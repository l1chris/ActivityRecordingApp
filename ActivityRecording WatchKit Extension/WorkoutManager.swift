/*

Abstract:
WorkoutManager is responsible for managing a workout.
A workout is necessary to access the heartrate and allows to run the App in the background.
*/

import Foundation
import HealthKit

import os

class WorkoutManager: NSObject {
    
    // Singleton
    static let sharedInstance = WorkoutManager()
    
    let logger = Logger(subsystem: "com.SimpleWatchConnectivityL5nl8W", category: "workout-manager")
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    let types = Set([HKObjectType.workoutType(),
                        HKObjectType.quantityType(forIdentifier: .heartRate)!])
    
    var sessionInProgress: Bool = false
    
    // Request authorization for HealthKit
    func requestAuthorization() {
        
        healthStore.requestAuthorization(toShare: types, read: types) { (success, error) in
            if !success {
                self.logger.error("HK Authorization failed: \(error)")
            } else {
                // TODO: Signal to Main Interface Controller
            }
        }
    }
    
    func checkAuthorization() -> Bool {
        let workoutStatus = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        let heartRateStatus = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .heartRate)!)
        
        if (workoutStatus == HKAuthorizationStatus.sharingAuthorized && heartRateStatus == HKAuthorizationStatus.sharingAuthorized) {
            return true
        }
        self.logger.log("Check unsuccessful; WorkoutStatus: \(workoutStatus.rawValue) HeartRateStatus: \(heartRateStatus.rawValue)")
        return false
    }
    
    func startWorkout() {
        
        // Do nothing if workout is already running
        if (session != nil) {
            return
        }

        // Configure the workout session
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        builder!.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: config)
        
        builder?.delegate = self
        
        let startDate = Date()
        session!.startActivity(with: startDate)
        builder!.beginCollection(withStart: startDate) { (success, error) in
            guard success else {
                self.logger.error("Error in beginCollection(): \(error)")
                return
            }
            self.sessionInProgress = true
        }
        
    }

    func stopWorkout() {
        
        if (session == nil) {
            return
        }
        self.sessionInProgress = false
        
        session?.end()
        session = nil
        builder?.endCollection(withEnd: Date(), completion: {(isCompleted: Bool, error: Error?) -> Void in return})
    }
    
    @Published var heartRate: Double = 0
    
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        
        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .newHeartRate, object: "NewHeartRate")
            }
        default:
            return
        }
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {return}
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            updateForStatistics(statistics)
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
}
