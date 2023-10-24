//
//  ContentViewExtensions.swift
//  mNativeUpdater
//
//  Created by Yinwei Z on 10/24/23.
//

import SwiftUI
import AppKit

extension ContentView {
    
    func getPasswordFromUser(completion: @escaping (String?, Bool) -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "We need your permission to update MCreator."
            alert.informativeText =
"""
This updater is intended to be used within a distribution of MCreator. Therefore, we will be moving existing versions of the app to the trash, instead of deleting them to prevent the updater from shutting down during the update. You will be automatically updated to the newest release avaialble from MCreator's official GitHub page.

To perform a full update, we'll need your password to mount and dismount installer disk images. Alternatively, you may choose to only download the new version, which does not require your password.
"""
            
            alert.alertStyle = .informational
            alert.addButton(withTitle: "􀵔 Full Update")
            alert.addButton(withTitle: "􀈄 Download Only")
            alert.addButton(withTitle: "Cancel")
            
            let inputTextField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 253, height: 24))
            inputTextField.placeholderString = "Enter Password for Full Update"
            alert.accessoryView = inputTextField
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                completion(inputTextField.stringValue, false)
            } else if response == .alertSecondButtonReturn {
                completion(nil, true)
            } else {
                completion(nil, false)
            }
        }
    }
    
    func startUpdateProcess() {
        getPasswordFromUser { password, isdownloadOnly in
            if isdownloadOnly {
                downloadOnly()
            } else if let password = password, !password.isEmpty {
                fullUpdate(with: password)
            }
        }
    }
    
    func downloadOnly() {
        guard let scriptPath = Bundle.main.path(forResource: "downloadOnly", ofType: "sh") else {
            print("Error: Script not found in bundle.")
            return
        }
        
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = "/bin/zsh"
        process.arguments = [scriptPath]
        process.standardOutput = pipe
        process.standardError = pipe
        
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()
        
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outHandle, queue: nil) { notification -> Void in
            let data = outHandle.availableData
            if data.count > 0 {
                if let str = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.log += str
                        
                        switch str {
                        case let s where s.contains("Fetching the latest release information"): self.progressValue = 5.0
                        case let s where s.contains("Locating the download resource for"): self.progressValue = 10.0
                        case let s where s.contains("Done"):
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                self.isUpdating = false
                                self.updateComplete = true
                            }
                        default:
                            if let range = str.range(of: "\\b\\d{1,3}\\b", options: .regularExpression),
                               let value = Int(str[range]),
                               value >= 0 && value <= 100 {
                                // Map the range 0-100 to 20-75
                                self.progressValue = 10.0 + (Double(value) / 100.0) * 90.0
                            }
                        }
                    }
                }
                outHandle.waitForDataInBackgroundAndNotify()
            }
        }
        
        var obs2: NSObjectProtocol?
        obs2 = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: process, queue: nil) { notification -> Void in
            if let localObs2 = obs2 {
                NotificationCenter.default.removeObserver(localObs2)
            }
        }
        
        
        process.launch()
    }
    
    func fullUpdate(with password: String) {
        guard let scriptPath = Bundle.main.path(forResource: "fullUpdate", ofType: "sh") else {
            print("Error: Script not found in bundle.")
            return
        }
        
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = "/bin/zsh"
        process.arguments = [scriptPath, password]
        process.standardOutput = pipe
        process.standardError = pipe
        
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outHandle, queue: nil) { notification -> Void in
            let data = outHandle.availableData
            if data.count > 0 {
                if let str = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.log += str
                        
                        switch str {
                        case let s where s.contains("Fetching the latest release information"): self.progressValue = 5.0
                        case let s where s.contains("Locating the download resource for"): self.progressValue = 10.0
                        case let s where s.contains("Detaching previously mounted MCreator volumes"): self.progressValue = 15.0
                        case let s where s.contains("Mounting the disk image"): self.progressValue = 75.0
                        case let s where s.contains("verified"): self.progressValue = 77.5
                        case let s where s.contains("Moving the old version"): self.progressValue = 80.0
                        case let s where s.contains("Copying the new version"): self.progressValue = 85.0
                        case let s where s.contains("Detaching the mounted volume"): self.progressValue = 90.0
                        case let s where s.contains("Deleting the disk image"):
                            self.progressValue = 100.0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                self.isUpdating = false
                                self.updateComplete = true
                            }
                        default:
                            // no progress for logs with checksumming
                            guard !str.contains("Checksumming"),
                                  !str.contains("CRC32") else {
                                break
                            }
                            
                            if let range = str.range(of: "\\b\\d{1,3}\\b", options: .regularExpression),
                               let value = Int(str[range]),
                               value >= 0 && value <= 100 {
                                // Map the range 0-100 to 20-75
                                self.progressValue = 20.0 + (Double(value) / 100.0) * 55.0
                            }
                        }
                    }
                }
                outHandle.waitForDataInBackgroundAndNotify()
            }
        }
        
        var obs2: NSObjectProtocol?
        obs2 = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: process, queue: nil) { notification -> Void in
            if let localObs2 = obs2 {
                NotificationCenter.default.removeObserver(localObs2)
            }
        }
        
        process.launch()
    }
}
