//
//  FileManager.swift
//  ActivityRecording WatchKit Extension
//
//  Created by Christian Schwenk on 08.11.22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import os

class DatafileManager: NSObject {
    
    // Singleton
    static let sharedInstance = DatafileManager()
    
    let logger = Logger(subsystem: "com.SimpleWatchConnectivityL5nl8W", category: "datafile-manager")
    
    let manager = FileManager.default
    let dataPath: String = "data.csv"
    var fileUrl: URL?
    
    
    func createFile() {
        fileUrl = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Create folder
        guard let newFolderUrl = fileUrl?.appendingPathComponent("motion-app-data") else { return }
        
        do {
            try manager.createDirectory(at: newFolderUrl, withIntermediateDirectories: true)
        } catch {
            logger.log("Cannot create folder")
        }
        
        // Create file
        let newFileUrl = newFolderUrl.appendingPathComponent("data.plist")
        print("File created at: " + newFileUrl.path)
        manager.createFile(atPath: newFileUrl.path, contents: nil)
        fileUrl = newFileUrl
        
        
    }
    
    func writeToFile(dataToWrite: Data) {
        // Check if file to write is available
        if (manager.isWritableFile(atPath: fileUrl!.path)) {
            do {
                try dataToWrite.write(to: fileUrl!)
            } catch {
                logger.log("Cannot write to file")
            }
        }
    }
}
