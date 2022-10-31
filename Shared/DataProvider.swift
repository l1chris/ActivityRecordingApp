/*

Abstract:
Defines the interface for providing payload for Watch Connectivity APIs.
*/

import UIKit

// Constants to access the payload dictionary
struct PayloadKey {
    static let timeStamp = "timeStamp"
}

// Interfaces for providing payload
protocol DataProvider {
    var message: [String: Any] { get }
    
    var file: URL { get }
    var fileMetaData: [String: Any] { get }
}

// Generate the default payload for commands
extension DataProvider {
    
    // Generate a dictionary containing a time stamp
    private func timedData() -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        let timeString = dateFormatter.string(from: Date())
        
        return [PayloadKey.timeStamp: timeString]
    }
    
    // Generate a message for sendMessage
    var message: [String: Any] {
        return timedData()
    }
    
    // Generate a file URL for transferFile
    // Use the log file for transferFile from the watch side
    var file: URL {
        #if os(watchOS)
        return CustomLogger.shared.getFileURL()
        #else
        fatalError("iPhone not intended to send files!")
        #endif
    }

    // Generate a file metadata dictionary, used as the payload for transferFile.
    var fileMetaData: [String: Any] {
        return timedData()
    }
}
