/*

Abstract:
Defines an interface to wrap Watch Connectivity APIs and bridge the UI.
*/

import UIKit
import WatchConnectivity

// Interface
protocol SessionCommands {
    func sendMessage(_ message: [String: Any])
    func transferFile(_ file: URL, metadata: [String: Any])
}

extension SessionCommands {

    // Function to send a message (-> dictionary)
    // Calls "sendMessage" of WCSession
    func sendMessage(_ message: [String: Any]) {
        var commandStatus = CommandStatus(command: .sendMessage, phrase: .sent)
        commandStatus.timedData = TimedData(message)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }
        
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
            commandStatus.phrase = .failed
            commandStatus.errorMessage = error.localizedDescription
            self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
        })
    }
    
    func sendNoFileAvailableMessage() {
        var commandStatus = CommandStatus(command: .receivedMessage, phrase: .sent)
        commandStatus.timedData = TimedData([PayloadKey.timeStamp: "No File Available"])

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }
        
        WCSession.default.sendMessage([PayloadKey.timeStamp: "No File Available"], replyHandler: nil)
    }
    
    // Function to transfer a file
    func transferFile(_ file: URL, metadata: [String: Any]) {
        var commandStatus = CommandStatus(command: .transferFile, phrase: .transferring)
        commandStatus.timedData = TimedData(metadata)

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated(with: commandStatus)
        }
        commandStatus.fileTransfer = WCSession.default.transferFile(file, metadata: metadata)
    }
    
    
    // Post a notification to the NotificationCenter
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: CommandStatus) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }

    // Handle unactivated session error
    private func handleSessionUnactivated(with commandStatus: CommandStatus) {
        var mutableStatus = commandStatus
        mutableStatus.phrase = .failed
        mutableStatus.errorMessage = "WCSession is not activated yet!"
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
    }
}
