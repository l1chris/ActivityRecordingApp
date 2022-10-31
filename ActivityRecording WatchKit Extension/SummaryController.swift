/*

Abstract:
Controller responsible for a finished recording.
*/

import Foundation
import WatchKit

class SummaryController: WKInterfaceController {
    
    @IBOutlet weak var elapsedTimeLabel: WKInterfaceLabel!
    
    static var instances = [SummaryController]()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        guard context != nil else {
            return
        }
        
        let ctx = context as! Double
        let elapsedTime = doubleToTimeString(val: ctx)
        elapsedTimeLabel.setText("\(elapsedTime)")
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    
    @IBAction func deleteBtnPressed() {
        
        CustomLogger.shared.clearLogs()
        
        WKInterfaceController.reloadRootPageControllers(
            withNames: ["MainInterfaceController"],
            contexts: [],
            orientation: .horizontal,
            pageIndex: 0)
    }
    
    
    @IBAction func saveBtnPressed() {
        
        WKInterfaceController.reloadRootPageControllers(
            withNames: ["MainInterfaceController"],
            contexts: [],
            orientation: .horizontal,
            pageIndex: 0)
    }
    
    func doubleToTimeString(val: Double) -> String {
    
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad

        let formattedString = formatter.string(from: TimeInterval(val))!
        return formattedString
    }
}
