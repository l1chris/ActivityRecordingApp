/*

Abstract:
The main view controller of the iOS app.
*/

import UIKit
import WatchConnectivity

class MainViewController: UIViewController {
        
    @IBOutlet weak var reachableLabel: UILabel!
    @IBOutlet weak var tableContainerView: UIView!
    @IBOutlet weak var logView: UITextView!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var tablePlaceholderView: UIView!
    
    let fileManager = FileManager.default
    
    private var command: Command!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add observers to the default NotificationCenter:
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).activationDidComplete(_:)),
            name: .activationDidComplete, object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).reachabilityDidChange(_:)),
            name: .reachabilityDidChange, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).dataDidFlow(_:)),
            name: .dataDidFlow, object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notification handlers for Observers
    
    @objc
    func activationDidComplete(_ notification: Notification) {
        updateReachabilityColor()
    }
    
    @objc
    func reachabilityDidChange(_ notification: Notification) {
        updateReachabilityColor()
    }
    
    // Logs status updates to the UI
    @objc
    func dataDidFlow(_ notification: Notification) {
        
        guard let commandStatus = notification.object as? CommandStatus else { return }
        command = commandStatus.command
        
        defer { noteLabel.isHidden = logView.text.isEmpty ? false: true }
        
        // If an error occurs, show the error message and return.
        if let errorMessage = commandStatus.errorMessage {
            log("! \(commandStatus.command.rawValue)...\(errorMessage)")
            return
        }
        
        if (commandStatus.file != nil) {
            
            guard let url = commandStatus.file?.fileURL else {
                print("No URL for file!")
                return
            }
            
            if (url.pathExtension == "log") {
                
                log("Receiving File ...")
                
                do {
                    let content = try Data(contentsOf: url)
                    
                    // Set file name to current date and time
                    let date = Date()
                    let dateformatter = DateFormatter()
                    dateformatter.dateFormat = "dd-MM-y_H:mm:ss"
                    let filename = dateformatter.string(from: date)
                    
                    let file = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                        .appendingPathComponent("\(filename).txt")
                        
                    guard let outputStream = OutputStream(url: file, append: true) else {
                        print("Unable to open file")
                        return
                    }

                    outputStream.open()
        
                    try outputStream.write(content)
                    outputStream.close()
                    
                    saveFile(url: file)
                    
                } catch {
                    print("Cannot read content")
                }
                
            }
        } else if (commandStatus.timedData != nil) {
            
            log("\(commandStatus.timedData!.timeStamp)")
        }
        
    }
    
    // MARK: Functions called by Notificaton handlers
    
    private func updateReachabilityColor() {
        var isReachable = false
        if WCSession.default.activationState == .activated {
            isReachable = WCSession.default.isReachable
        }
        reachableLabel.backgroundColor = isReachable ? .green : .red
    }
    
    private func log(_ message: String) {
        logView.text = logView.text! + "\n\n" + message
        logView.scrollRangeToVisible(NSRange(location: logView.text.count, length: 1))
    }
    
    private func saveFile(url: URL) {
        // Ask user to save file to device
        DispatchQueue.main.async {
            let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityController.excludedActivityTypes = [.postToTwitter, .postToFacebook]
            self.present(activityController, animated: true, completion: nil)
        }
    }
}

extension OutputStream {
    enum OutputStreamError: Error {
        case stringConversionFailure
        case bufferFailure
        case writeFailure
    }
    
    func write(_ data: Data) throws {
        try data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) throws in
            guard var pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw OutputStreamError.bufferFailure
            }

            var bytesRemaining = buffer.count

            while bytesRemaining > 0 {
                let bytesWritten = write(pointer, maxLength: bytesRemaining)
                if bytesWritten < 0 {
                    throw OutputStreamError.writeFailure
                }

                bytesRemaining -= bytesWritten
                pointer += bytesWritten
            }
        }
    }
}

