/*

Abstract:
Wraps the command status.
*/

import UIKit
import WatchConnectivity

// Commands
enum Command: String {
    case sendMessage = "Initiate File Transfer"
    case receivedMessage = "No File Available"
    case transferFile = "Transfer File"
}

enum Phrase: String {
    case sent = "Sent Message"
    case received = "Received Message"
    case replied = "Received Response"
    case transferring = "Transferring"
    case canceled = "Canceled"
    case finished = "Finished"
    case failed = "Failed"
}

// Wrap a timed data payload dictionary with a stronger type.
struct TimedData {
    var timeStamp: String
    
    var timedData: [String: Any] {
        return [PayloadKey.timeStamp: timeStamp]
    }
    
    init(_ timedData: [String: Any]) {
        guard let timeStamp = timedData[PayloadKey.timeStamp] as? String else {
                fatalError("Dictionary doesn't have right keys!")
        }
        self.timeStamp = timeStamp
    }
    
    init(_ timedData: Data) {
        let data = ((try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(timedData)) as Any??)
        guard let dictionary = data as? [String: Any] else {
            fatalError("Failed to unarchive a dictionary!")
        }
        self.init(dictionary)
    }
}

// Wrap the command's status to bridge the commands status and UI.
struct CommandStatus {
    var command: Command
    var phrase: Phrase
    var timedData: TimedData?
    var fileTransfer: WCSessionFileTransfer?
    var file: WCSessionFile?
    var errorMessage: String?
    
    init(command: Command, phrase: Phrase) {
        self.command = command
        self.phrase = phrase
    }
}
