/*

Abstract:
The main interface controller of the WatchKit extension.
*/

import Foundation
import WatchKit
import WatchConnectivity

import os

struct ControllerID {
    static let mainInterfaceController = "MainInterfaceController"
}

class MainInterfaceController: WKInterfaceController, DataProvider, SessionCommands {
    
    let logger = Logger(subsystem: "com.SimpleWatchConnectivityL5nl8W", category: "main-interface")
    
    static var instances = [MainInterfaceController]()
    private var command: Command!
    
    // Initialization
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let context = context as? CommandStatus {
    
            command = context.command
            
            type(of: self).instances.removeAll()
            type(of: self).instances.append(self)
            
        } else {
            reloadRootController()
        }
        
        // Add observers to the default NotificationCenter:
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).dataDidFlow(_:)),
            name: .dataDidFlow, object: nil
        )
         
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).activationDidComplete(_:)),
            name: .activationDidComplete, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).reachabilityDidChange(_:)),
            name: .reachabilityDidChange, object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Called when user raises his wrist
    override func willActivate() {
        super.willActivate()
        guard command != nil else { return } // Do nothing for first-time loading
    }
    
    // Called when user lowers his wrist
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    // Reload this controller
    private func reloadRootController(with currentContext: CommandStatus? = nil) {
        //print("reloadRootController")
        
        // Authorize HealthKit (to read the heart rate)
        WorkoutManager.sharedInstance.requestAuthorization()
        
        let commands: [Command] = [.sendMessage]
        var contexts = [CommandStatus]()
        for aCommand in commands {
            var commandStatus = CommandStatus(command: aCommand, phrase: .finished)
            
            if let currentContext = currentContext, aCommand == currentContext.command {
                commandStatus.phrase = currentContext.phrase
                commandStatus.timedData = currentContext.timedData
            }
            contexts.append(commandStatus)
        }
        
        let names = Array(repeating: ControllerID.mainInterfaceController, count: contexts.count)

        WKInterfaceController.reloadRootPageControllers(withNames: names, contexts: contexts as [AnyObject], orientation: .horizontal, pageIndex: 0)
    }
    
    // MARK: Notification handlers for Observers
    
    @objc
    func dataDidFlow(_ notification: Notification) {
        guard let commandStatus = notification.object as? CommandStatus else { return }
        
        // Check if data is from the current channel
        if (commandStatus.command == command) {
            
            // Initiate file transfer
            if (commandStatus.command == Command.sendMessage) {
                // Empty file
                if (CustomLogger.shared.content() == "") {
                    sendNoFileAvailableMessage()
                } else {
                    transferFile(file, metadata: fileMetaData)
                }
            }
            
        }
        
    }

    @objc
    func activationDidComplete(_ notification: Notification) {
    }
    
    @objc
    func reachabilityDidChange(_ notification: Notification) {
    }
    
    @IBAction func btnPressed() {
        let x = "btnPressed"
        pushController(withName: "SelectionHostingController", context: x)
    }
    
}
