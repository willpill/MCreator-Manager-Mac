//
//  ContentViewExtensions.swift
//  mNativeUpdater
//
//  Created by Yinwei Z on 10/24/23.
//

import SwiftUI
import AppKit

extension ContentView {
    
    func getUserUpdateChoice(completion: @escaping (Bool?) -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Which kind of update would you like to perform?"
            alert.informativeText =
            """
            You will be automatically updated to the newest release available from MCreator's official GitHub page.
            
            To perform a full update, we'll need your permission. Alternatively, you may choose to only download the new version's disk image.
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "􀵔 Perform Full Update")
            alert.addButton(withTitle: "􀈄 Download Disk Image Only")
            alert.addButton(withTitle: "Cancel")
            
            if let window = NSApplication.shared.mainWindow {
                alert.beginSheetModal(for: window) { response in
                    switch response {
                    case .alertFirstButtonReturn:
                        completion(true)
                    case .alertSecondButtonReturn:
                        completion(false)
                    default:
                        self.isUpdating = false
                        completion(nil)
                    }
                }
            } else {
                let response = alert.runModal()
                switch response {
                case .alertFirstButtonReturn:
                    completion(true)
                case .alertSecondButtonReturn:
                    completion(false)
                default:
                    self.isUpdating = false
                    completion(nil)
                }
            }
        }
    }
    
    func getPasswordFromUser(completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "We need your permission to update MCreator."
            alert.informativeText =
            """
            To perform a full update, we need your password to manage installer disk images.
            We will be moving existing versions of MCreator to the trash.
            """
            alert.alertStyle = .informational
            let inputTextField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
            inputTextField.placeholderString = "Enter Password"
            alert.accessoryView = inputTextField
            alert.addButton(withTitle: "Proceed")
            alert.addButton(withTitle: "Cancel")
            
            if let window = NSApplication.shared.mainWindow {
                alert.beginSheetModal(for: window) { response in
                    switch response {
                    case .alertFirstButtonReturn:
                        completion(inputTextField.stringValue)
                    default:
                        self.isUpdating = false
                        completion(nil)
                    }
                }
            } else {
                let response = alert.runModal()
                switch response {
                case .alertFirstButtonReturn:
                    completion(inputTextField.stringValue)
                default:
                    self.isUpdating = false
                    completion(nil)
                }
            }
        }
    }
    
    
    func startUpdateProcess() {
        getUserUpdateChoice { updateChoice in
            switch updateChoice {
            case true:
                getPasswordFromUser { password in
                    if let password = password, !password.isEmpty {
                        fullUpdate(with: password)
                    }
                }
            case false:
                downloadOnly()
            default:
                // User canceled or closed the alert, no action needed
                break
            }
        }
    }
    
    func downloadOnly() {
        let scriptContent = downloadOnlySH
        
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", scriptContent]
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
        let scriptContent = fullUpdateSH
        
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", scriptContent, password]
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
