/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages the outstanding file transfers.
*/

import Foundation
import WatchKit
import WatchConnectivity

extension ControllerID {
    static let fileTransfersController = "FileTransfersController"
    static let fileTransferRowController = "FileTransferRowController"
}

class FileTransfersController: UserInfoTransfersController {

    // Hold the file transfer observers to keep observing the progress.
    //
    private var fileTransferObservers = FileTransferObservers()
    
    override var rowType: String {
        return ControllerID.fileTransferRowController
    }
    
    // Rebuild the fileTransferObservers every time transfersStore changes.
    //
    override var transfers: [SessionTransfer] {
        guard transfersStore == nil else { return transfersStore! }
        
        fileTransferObservers = FileTransferObservers()
        
        let fileTransfers = WCSession.default.outstandingFileTransfers
        transfersStore = fileTransfers
        
        // The observing handler can run in the background, so dispatch
        // the UI update code to the main queue and use the table data at the moment.
        //
        for transfer in fileTransfers {
            fileTransferObservers.observe(transfer) { progress in
                DispatchQueue.main.async {
                    guard let index = self.transfers.firstIndex(where: {
                        ($0 as? WCSessionFileTransfer)?.progress === progress }) else { return }
                    
                    if let row = self.table.rowController(at: index) as? FileTransferRowController {
                        row.progressLabel.setText(progress.localizedDescription)
                    }
                }
            }
        }
        return transfersStore!
    }
}

class FileTransferRowController: UserInfoTransferRowController {
    @IBOutlet var progressLabel: WKInterfaceLabel!
    
    // Update the table cell with the transfer's timed color.
    //
    override func update(with transfer: SessionTransfer) {
        titleLabel.setText(transfer.timedColor.timeStamp)
        titleLabel.setTextColor(transfer.timedColor.color)
        progressLabel.setText("%0 completed")
        progressLabel.setTextColor(transfer.timedColor.color)
    }
}
