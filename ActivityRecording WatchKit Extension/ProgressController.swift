/*

Abstract:
Controller responsible for recording an activity.
*/

import Foundation
import WatchKit
import os

struct DataEntity: Encodable {
    let motionData: MotionDataEntity
    let heartRate: Double
    
    init(motionData: MotionDataEntity, heartRate: Double) {
        self.motionData = motionData
        self.heartRate = heartRate
    }
}

class ProgressController: WKInterfaceController {
    
    @IBOutlet weak var statusLabel: WKInterfaceLabel!
    @IBOutlet weak var activeRecordingGroup: WKInterfaceGroup!
    @IBOutlet weak var timerLabel: WKInterfaceTimer!
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    
    let logger = Logger(subsystem: "com.SimpleWatchConnectivityL5nl8W", category: "progress-interface")
    
    static var instances = [ProgressController]()
    
    private var motionManager = CoreMotionManager()
    
    private var workoutType: String = ""
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        workoutType = context as! String
        
        motionManager.delegate = self
        
        // Add observers to the default NotificationCenter:
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).newHeartRate(_:)),
            name: .newHeartRate, object: nil
        )
        
        updateUI()
        
    }
    
    @objc
    func newHeartRate(_ notification: Notification) {
        let heartRateAsString: String = String(format: "%.1f", WorkoutManager.sharedInstance.heartRate)
        heartRateLabel.setText("\(heartRateAsString) BPM")
    }
    
    private func updateUI(with commandStatus: CommandStatus? = nil, errorMessage: String? = nil) {
        
        // Start CoreMotionManager
        motionManager.startQueuedUpdates()
        
        // Error handling
        if let errorMessage = errorMessage {
            statusLabel.setText("! \(errorMessage)")
            return
        }
        
        // Check HealthKit Authorization before progressing
        if (WorkoutManager.sharedInstance.checkAuthorization() == false) {
            logger.log("WorkoutManager not authorized")
            return
        }
        
        // Check Accelerometer & Gyro before progressing
        if (motionManager.checkSensors() == false) {
            logger.log("MotionManager not ready")
            return
        }
        
        // Start WorkoutManager
        WorkoutManager.sharedInstance.startWorkout()
        
        statusLabel.setText("Recording...")
        
        timerLabel.setDate(Date())
        timerLabel.start()
        
        let heartRateAsString: String = String(format: "%.1f", WorkoutManager.sharedInstance.heartRate)
        heartRateLabel.setText("\(heartRateAsString) BPM")
    }
    
    @IBAction func handleStopRecording() {
        
        let interval = WorkoutManager.sharedInstance.session?.associatedWorkoutBuilder().elapsedTime
        
        WorkoutManager.sharedInstance.stopWorkout()
        motionManager.stopQueuedUpdates()
        
        timerLabel.stop()
        
        WKInterfaceController.reloadRootPageControllers(
            withNames: ["SummaryController"],
            contexts: [interval ?? 0],
            orientation: .horizontal,
            pageIndex: 0)
    }
    
}

extension ProgressController: CoreMotionManagerDelegate {
    
    // Called when new data is available
    // Responsible for writing data to file
    func handleNewMotionData(newMotionData: MotionDataEntity, magnetometerAvailable: Bool) {
        
        if (WorkoutManager.sharedInstance.sessionInProgress && WorkoutManager.sharedInstance.heartRate != 0) {
            let heartRate = WorkoutManager.sharedInstance.heartRate
            let motionData = newMotionData
            
            if (!magnetometerAvailable) {
                
                let dataString = "\(workoutType), \(heartRate),\(motionData.accelerationX),\(motionData.accelerationY),\(motionData.accelerationZ),\(motionData.rotationRateX),\(motionData.rotationRateY),\(motionData.rotationRateZ)"
                
                CustomLogger.shared.append(line: dataString)
                
            } else {
                
                let dataString = "\(workoutType), \(heartRate),\(motionData.accelerationX),\(motionData.accelerationY),\(motionData.accelerationZ),\(motionData.rotationRateX),\(motionData.rotationRateY),\(motionData.rotationRateZ), \(motionData.magneticFieldX!), \(motionData.magneticFieldY!), \(motionData.magneticFieldZ!)"
                
                CustomLogger.shared.append(line: dataString)
            }
        }
    }
}
