//
//  ContentViewExtensions.swift
//  mUpdater
//
//  Created by Yinwei Z on 10/24/23.
//

import SwiftUI
import AppKit

extension ContentView {
    
    // MARK: - UI Components
    func showAlert(parentWindow: NSWindow?, messageText: String, informativeText: String, buttons: [String], inputField: Bool = false, completion: @escaping (Int, String?) -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = messageText
            alert.informativeText = informativeText
            alert.alertStyle = .informational

            for button in buttons {
                alert.addButton(withTitle: button)
            }

            if inputField {
                let inputTextField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
                inputTextField.placeholderString = "Enter Password"
                alert.accessoryView = inputTextField
            }
            
            if let parentWindow = parentWindow {
                alert.beginSheetModal(for: parentWindow) { (response) in
                    let text = (alert.accessoryView as? NSTextField)?.stringValue
                    completion(response.rawValue, text)
                }
            } else {
                let response = alert.runModal()
                let text = (alert.accessoryView as? NSTextField)?.stringValue
                completion(response.rawValue, text)
            }
        }
    }

    
    // MARK: - Interaction
    func getUserUpdateChoice(completion: @escaping (Bool?) -> Void) {
        showAlert(
            parentWindow: NSApplication.shared.windows.first(where: { $0.isMainWindow}),
            messageText: "Which kind of update would you like to perform?",
            informativeText: """
            You will be automatically updated to the newest release available from MCreator's official GitHub page.
            
            To perform a full update, we'll need your permission. Alternatively, you may choose to only download the new version's disk image.
            """,
            buttons: ["􀵔 Perform Full Update", "􀈄 Download Disk Image Only", "Cancel"]
        ) { (response, _) in
            switch response {
            case NSApplication.ModalResponse.alertFirstButtonReturn.rawValue:
                completion(true)
            case NSApplication.ModalResponse.alertSecondButtonReturn.rawValue:
                completion(false)
            default:
                completion(nil)
            }
        }
    }
    
    func getPasswordFromUser(completion: @escaping (String?) -> Void) {
        showAlert(
            parentWindow: NSApplication.shared.windows.first(where: { $0.isMainWindow}), 
            messageText: "We need your permission to update MCreator.",
            informativeText: """
            To perform a full update, we need your password to manage installer disk images.
            
            We will be moving existing versions of MCreator to the trash.
            """,
            buttons: ["Proceed", "Cancel"],
            inputField: true
        ) { (response, text) in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn.rawValue {
                completion(text)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Update Process
    func startUpdateProcess() {
        getUserUpdateChoice { updateChoice in
            switch updateChoice {
            case true:
                getPasswordFromUser { password in
                    if let password = password, !password.isEmpty {
                        self.isUpdating = true
                        self.fullUpdate(with: password)
                    }
                }
            case false:
                self.isUpdating = true
                self.downloadOnly()
            default:
                break
            }
        }
    }
    
    func downloadOnly() {
        var scriptContent: String
        if viewModel.selectedTab == .snapshot {
            scriptContent = downloadOnlySHSnap
        } else {
            scriptContent = downloadOnlySH
        }
        
        executeScript(with: scriptContent)
    }
    
    
    func fullUpdate(with password: String) {
        var scriptContent: String
        if viewModel.selectedTab == .snapshot {
            scriptContent = fullUpdateSHSnap
        } else {
            scriptContent = fullUpdateSH
        }
        
        executeScript(with: scriptContent, password: password)
    }
    func executeScript(with content: String, password: String? = nil) {
        let process = Process()
        let pipe = Pipe()
        
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", content, password].compactMap { $0 }
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
                        case let s where s.contains("Fetching the latest"): self.progressValue = 5.0
                        case let s where s.contains("Locating the download resource for"): self.progressValue = 10.0
                        case let s where s.contains("Checksumming"): self.progressValue = 93.0
                        case let s where s.contains("Finishing Up"):
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.isUpdating = false
                                self.updateComplete = true
                            }
                        case let s where s.contains("Deleting the disk image"):
                            self.progressValue = 100.0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.isUpdating = false
                                self.updateComplete = true
                            }
                        case let s where s.contains("No prereleases") || s.contains("An error occurred") || s.contains("Sorry, try again"):
                            process.terminate()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.isUpdating = false
                                
                                let errorAlert = NSAlert()
                                errorAlert.messageText = "We ran into an error. Refer to the logs for more information."
                                errorAlert.informativeText = "Check that you've entered the correct password, and have the necessary permissions."
                                errorAlert.alertStyle = .critical
                                errorAlert.addButton(withTitle: "OK")
                                
                                if let window = NSApplication.shared.mainWindow {
                                    errorAlert.beginSheetModal(for: window, completionHandler: nil)
                                } else {
                                    errorAlert.runModal()
                                }
                            }
                        default:
                            // no progress for logs with crc32ing
                            guard !str.contains("CRC32") else {
                                break
                            }
                            
                            if let range = str.range(of: "\\b\\d{1,3}\\b", options: .regularExpression),
                               let value = Int(str[range]),
                               value >= 0 && value <= 100 {
                                self.progressValue = 10.0 + (Double(value) / 100.0) * 80.0
                            }
                        }
                    }
                    outHandle.waitForDataInBackgroundAndNotify()
                }
            }
        }
        
        let obsQueue = DispatchQueue(label: "scriptExecutionQueue")
        var obs2: NSObjectProtocol?
        
        obsQueue.async {
            obs2 = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: process, queue: nil) { notification -> Void in
                obsQueue.async {
                    if let localObs2 = obs2 {
                        NotificationCenter.default.removeObserver(localObs2)
                    }
                }
            }
        }
        
        process.launch()
    }
}
