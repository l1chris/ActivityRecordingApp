/*

Abstract:
CoreMotionManager is responsible starting/stopping the sensors.
*/

import Foundation
import CoreMotion

import os

protocol CoreMotionManagerDelegate: AnyObject {
    func handleNewMotionData(newMotionData: MotionDataEntity, magnetometerAvailable: Bool)
}


struct MotionDataEntity: Encodable {
    let accelerationX: Double
    let accelerationY: Double
    let accelerationZ: Double
    let rotationRateX: Double
    let rotationRateY: Double
    let rotationRateZ: Double
    let magneticFieldX: Double?
    let magneticFieldY: Double?
    let magneticFieldZ: Double?
    
    init(accelerationX: Double, accelerationY: Double, accelerationZ: Double, rotationRateX: Double, rotationRateY: Double, rotationRateZ: Double, magneticFieldX: Double?=nil, magneticFieldY: Double?=nil, magneticFieldZ: Double?=nil) {
        self.accelerationX = accelerationX
        self.accelerationY = accelerationY
        self.accelerationZ = accelerationZ
        self.rotationRateX = rotationRateX
        self.rotationRateY = rotationRateY
        self.rotationRateZ = rotationRateZ
        self.magneticFieldX = magneticFieldX
        self.magneticFieldY = magneticFieldY
        self.magneticFieldZ = magneticFieldZ
    }
}

class CoreMotionManager: NSObject {
    
    let logger = Logger(subsystem: "com.SimpleWatchConnectivityL5nl8W", category: "motion-manager")
    
    var motion = CMMotionManager()
    var queue = OperationQueue()
    
    var dataEntity: MotionDataEntity?
    var magnetometerAvailable = false
    
    weak var delegate: CoreMotionManagerDelegate?
    
    var updateInterval = 1.0 / 100.0 // 100 Hertz
    
    func startQueuedUpdates() {
        
        if (self.motion.isDeviceMotionAvailable) {
            self.motion.deviceMotionUpdateInterval = updateInterval
            self.motion.showsDeviceMovementDisplay = true
            self.motion.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical, to: self.queue, withHandler: { (data, error) in
                
                if (data != nil) {
                   
                    // Acceleromter
                    let accelerationX = data?.userAcceleration.x
                    let accelerationY = data?.userAcceleration.y
                    let accelerationZ = data?.userAcceleration.z
                    
                    // Gyro
                    let rotationRateX = data?.rotationRate.x
                    let rotationRateY = data?.rotationRate.y
                    let rotationRateZ = data?.rotationRate.z
                    
                    // Magnetometer
                    let magneticFieldX = data?.magneticField.field.x
                    let magneticFieldY = data?.magneticField.field.y
                    let magneticFieldZ = data?.magneticField.field.z
                    
                    /*
                    self.logger.log("magneticFieldX: \(magneticFieldX?.debugDescription ?? "__")")
                    self.logger.log("magneticFieldY: \(magneticFieldY?.debugDescription ?? "__")")
                    self.logger.log("magneticFieldZ: \(magneticFieldZ?.debugDescription ?? "__")")
                    */
                    
                    // Check if magnetic data is available
                    if (magneticFieldX != nil) {
                        
                        self.magnetometerAvailable = true
                        
                        self.dataEntity = MotionDataEntity(accelerationX: accelerationX!, accelerationY: accelerationY!, accelerationZ: accelerationZ!, rotationRateX: rotationRateX!, rotationRateY: rotationRateY!, rotationRateZ: rotationRateZ!, magneticFieldX: magneticFieldX, magneticFieldY: magneticFieldY, magneticFieldZ: magneticFieldZ)
                        
                    } else {
                        
                        self.dataEntity = MotionDataEntity(accelerationX: accelerationX!, accelerationY: accelerationY!, accelerationZ: accelerationZ!, rotationRateX: rotationRateX!, rotationRateY: rotationRateY!, rotationRateZ: rotationRateZ!)
                    }
                    
                    self.delegate?.handleNewMotionData(newMotionData: self.dataEntity!, magnetometerAvailable: self.magnetometerAvailable)
                    
                    /*
                    self.logger.log("AccelermoterX: \(accelerationX?.debugDescription ?? "__")")
                    self.logger.log("AccelermoterY: \(accelerationY?.debugDescription ?? "__")")
                    self.logger.log("AccelermoterZ: \(accelerationZ?.debugDescription ?? "__")")
                    self.logger.log("gyroX: \(rotationRateX?.debugDescription ?? "__")")
                    self.logger.log("gyroY: \(rotationRateY?.debugDescription ?? "__")")
                    self.logger.log("gyroZ: \(rotationRateZ?.debugDescription ?? "__")")
                    */
                }
            })
        } else {
            self.logger.log("DeviceMotion unavailable")
        }
        
    }
    
    func stopQueuedUpdates() {
        self.motion.stopDeviceMotionUpdates()
    }
    
    func checkSensors() -> Bool {
        if (motion.isDeviceMotionActive) {
            return true
        }
        self.logger.log("Sensors not ready")
        return false
    }
    
}
