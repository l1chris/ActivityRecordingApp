/*

Abstract:
Utility for writing data into a log file.
*/

import Foundation

class CustomLogger {
    
    // Singleton
    static let shared = CustomLogger()
    
    private var fileHandle: FileHandle!

    private init() {
        fileHandle = try? FileHandle(forUpdating: fileURL)
        assert(fileHandle != nil, "Failed to create the file handle!")
    }
    
    // Return the folder URL, and create the folder if it doesn't exist
    private var _folderURL: URL?
    private var folderURL: URL! {
        guard _folderURL == nil else { return _folderURL }
        
        var folderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        folderURL.appendPathComponent("Logs")
        
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            } catch {
                print("Failed to create the log folder: \(folderURL)! \n\(error)")
                return nil // To trigger crash
            }
        }
        _folderURL = folderURL
        return folderURL
    }
    
    // Return the file URL, and create the file if it doesn't exist
    private var _fileURL: URL?
    private var fileURL: URL! {
        guard _fileURL == nil else { return _fileURL }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: Date())
    
        var fileURL: URL = self.folderURL
        fileURL.appendPathComponent("\(dateString).log")
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            if !FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil) {
                print("Failed to create the log file: \(fileURL)!")
                return nil // To trigger crash
            }
        }
        _fileURL = fileURL
        return fileURL
    }
    
    // Avoid creating DateFormatter frequently, as Logger counts into the execution budget.
    private lazy var timeStampFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        return dateFormatter
    }()
    
    // Get the current log file URL
    func getFileURL() -> URL {
        return performBlockAndWait { return fileURL }
    }
    
    private func performBlockAndWait<T>(_ block: () -> T) -> T {
        return ioQueue.sync {
            return block()
        }
    }
    
    // Use this dispatch queue to make the log file access thread-safe.
    // Public methods use performBlockAndWait to access the resource; private methods don't.
    private lazy var ioQueue: DispatchQueue = {
        return DispatchQueue(label: "ioQueue")
    }()
    
    // Append a line of text to the end of the file.
    // Use FileHandle to seek to the end directly.
    func append(line: String) {
        let d = Date()
        let df = DateFormatter()
        df.dateFormat = "y-MM-dd H:mm:ss.SSSS"
        
        let timeStamp = df.string(from: d)
        let timedLine = timeStamp + "," + line + "\n"
        
        if let data = timedLine.data(using: .utf8) {
            performBlockAndWait {
                self.fileHandle.seekToEndOfFile()
                self.fileHandle.write(data)
            }
        }
    }
    
    // Read the file content and return it as a string.
    func content() -> String {
        return performBlockAndWait {
            fileHandle.seek(toFileOffset: 0) // Read from the very beginning.
            return String(data: fileHandle.availableData, encoding: .utf8) ?? ""
        }
    }
    
    // Clear all logs. Reset the folder and file URL for later use.
    func clearLogs() {
        performBlockAndWait {
            self.fileHandle.closeFile()
            do {
                try FileManager.default.removeItem(at: self.folderURL)
            } catch {
                print("Failed to clear the log folder!\n\(error)")
            }
            
            // Create a new file handle.
            self._folderURL = nil
            self._fileURL = nil
            self.fileHandle = try? FileHandle(forUpdating: self.fileURL)
            assert(self.fileHandle != nil, "Failed to create the file handle!")
        }
    }
}
