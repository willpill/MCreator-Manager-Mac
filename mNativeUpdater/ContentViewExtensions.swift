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
        getPasswordFromUser { password, downloadOnly in
            if downloadOnly {
                runDownloadOnlyScript()
            } else if let password = password, !password.isEmpty {
                runShellScript(with: password)
            }
        }
    }
    
    func runDownloadOnlyScript() {
        let script = """
        #!/bin/zsh
        
        LOG_FILE="$HOME/Downloads/updater_log_$(date +%Y%m%d%H%M%S).log"
        exec > >(tee "$LOG_FILE") 2>&1
        
        echo "Starting Download Only to ~/Downloads..."
        
        arch=$(uname -m)
        if [ "$arch" = "x86_64" ]; then
            dmg_arch="64bit"
        else
            dmg_arch="aarch64"
        fi
        
        echo "Fetching the latest release information..."
        release=$(curl -s https://api.github.com/repos/MCreator/MCreator/releases/latest)
        
        echo "Locating the download resource for $arch architecture..."
        mcrUrl=$(echo "$release" | grep -o "https://[^']*Mac.$dmg_arch.dmg" | head -n 1)
        mcrFile=$(basename "$mcrUrl")
        
        echo "Downloading $mcrFile..."
        curl -L -o "$HOME/Downloads/$mcrFile" "$mcrUrl"
        
        echo "Done"
        """
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", script]
        
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()
        
        var obs1 : NSObjectProtocol!
        obs1 = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outHandle, queue: nil) { notification -> Void in
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
        
        var obs2 : NSObjectProtocol!
        obs2 = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: process, queue: nil) { [localObs2 = obs2] notification -> Void in
            NotificationCenter.default.removeObserver(localObs2!)
        }
        
        process.launch()
    }
    
    func runShellScript(with password: String) {
        let script = """
        #!/bin/zsh
        
        LOG_FILE="$HOME/Downloads/updater_log_$(date +%Y%m%d%H%M%S).log"
        exec > >(tee "$LOG_FILE") 2>&1
        echo "Starting Update..."
        
        check_error() {
            if [ $? -ne 0 ]; then
                echo "An error occurred. Saved log file to $HOME/Downloads."
                exit 1
            fi
        }
        
        arch=$(uname -m)
        if [ "$arch" = "x86_64" ]; then
            dmg_arch="64bit"
        else
            dmg_arch="aarch64"
        fi
        
        echo "Fetching the latest release information..."
        release=$(curl -s https://api.github.com/repos/MCreator/MCreator/releases/latest)
        check_error
        
        echo "Locating the download resource for $arch architecture..."
        mcrUrl=$(echo "$release" | grep -o "https://[^']*Mac.$dmg_arch.dmg" | head -n 1)
        mcrFile=$(basename "$mcrUrl")
        
        echo "Detaching previously mounted MCreator volumes..."
        echo "\(password)" | sudo -S hdiutil detach /Volumes/MCreator*/
        
        echo "Downloading $mcrFile..."
        curl -L -o "$HOME/Downloads/$mcrFile" "$mcrUrl"
        check_error
        
        echo "Mounting the disk image..."
        hdiutil attach "$HOME/Downloads/$mcrFile"
        check_error
        
        echo "Moving the old version to the Trash..."
        
        # If the application already exists in the Trash
        if [ -e ~/.Trash/MCreator.app ]; then
            counter=1
            # While a file/folder with that name exists in the Trash, increment counter
            while [ -e ~/.Trash/MCreator-${counter}.app ]; do
                counter=$((counter + 1))
            done
            echo "\(password)" | sudo -S mv /Applications/MCreator.app ~/.Trash/MCreator-${counter}.app
        else
            echo "\(password)" | sudo -S mv /Applications/MCreator.app ~/.Trash/
        fi
        check_error
        
        echo "Copying the new version to Applications folder..."
        echo "\(password)" | sudo -S find /Volumes/MCreator*/ -name "*.app" -exec cp -R {} /Applications/ \\;
        check_error
        
        echo "Detaching the mounted volume..."
        echo "\(password)" | sudo -S hdiutil detach /Volumes/MCreator*/
        check_error
        
        echo "Deleting the disk image..."
        rm "$HOME/Downloads/$mcrFile"
        check_error
        
        echo "Opening MCreator.app..."
        open /Applications/MCreator.app
        check_error
        """
        
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", script]
        
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()
        
        var obs1 : NSObjectProtocol!
        obs1 = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outHandle, queue: nil) { notification -> Void in
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
        
        var obs2 : NSObjectProtocol!
        obs2 = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: process, queue: nil) { [localObs2 = obs2] notification -> Void in
            NotificationCenter.default.removeObserver(localObs2!)
        }
        
        process.launch()
    }
}
