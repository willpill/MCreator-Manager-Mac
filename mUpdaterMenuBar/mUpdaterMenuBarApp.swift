//
//  mUpdaterMenuBarApp.swift
//  mUpdaterMenuBar
//
//  Created by Yinwei Z on 10/27/23.
//

import SwiftUI
import Foundation

@main
struct mUpdaterMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { // Use Settings instead of WindowGroup
            Text("") // Placeholder, won't be shown
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBar: NSStatusBar!
    var statusBarItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up the status bar item
        statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.button?.title = "􀇯"
        
        // Set the target and action for the button
        statusBarItem.button?.target = self
        statusBarItem.button?.action = #selector(checkForUpdatesClicked)
        
        // Check for updates immediately upon launch
        checkForUpdates()
        
        // Set up a timer to check for updates every 10 minutes
        Timer.scheduledTimer(withTimeInterval: 100, repeats: true) { _ in
            self.checkForUpdates()
        }
    }
    
    @objc func checkForUpdatesClicked() {
        NSWorkspace.shared.launchApplication("mUpdater")
    }
    
    func getCurrentVersion() -> String? {
        let appPath = "/Applications/MCreator.app" as NSString
        let infoPlistPath = appPath.appendingPathComponent("Contents/Info.plist")
        if let infoDict = NSDictionary(contentsOfFile: infoPlistPath),
           let version = infoDict["CFBundleVersion"] as? String {
            return version
        } else {
            print("Error fetching local version.") // Diagnostic print
            return nil
        }
    }
    
    func getLatestVersion(completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.github.com/repos/MCreator/MCreator/releases/latest")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching latest version from GitHub: \(error)") // Diagnostic print
            }
            guard let data = data else {
                completion(nil)
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    completion(tagName)
                } else {
                    print("Error parsing JSON from GitHub.") // Diagnostic print
                    completion(nil)
                }
            } catch {
                print("Error with JSON serialization: \(error)") // Diagnostic print
                completion(nil)
            }
        }
        task.resume()
    }
    
    
    func checkForUpdates() {
        guard let currentVersion = getCurrentVersion() else {
            DispatchQueue.main.async {
                self.statusBarItem.button?.title = "􀁟"
            }
            return
        }
        getLatestVersion { latestVersion in
            DispatchQueue.main.async {
                self.statusBarItem.button?.title = "􀇯"
                guard let latestVersion = latestVersion else {
                    self.statusBarItem.button?.title = "􀁟"
                    return
                }
                let currentVersionPrefix = String(currentVersion.prefix(6))
                let latestVersionPrefix = String(latestVersion.prefix(6))
                if latestVersionPrefix > currentVersionPrefix {
                    self.statusBarItem.button?.title = "􀁷"
                } else {
                    print("ok")
                    self.statusBarItem.button?.title = "􀁣"
                }
            }
        }
    }
}
