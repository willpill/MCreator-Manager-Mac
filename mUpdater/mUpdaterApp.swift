//
//  mUpdaterApp.swift
//  mUpdater
//
//  Created by Yinwei Z on 10/22/23.
//

import SwiftUI
import Foundation

@main
struct mUpdaterApp: App {
    @StateObject private var viewModel = UpdaterViewModel()
    @State private var showHelpSheet = false
    @State private var showAlertFor: UpdateAction? = nil
    @State private var isAgentEnabled: Bool = UserDefaults.standard.bool(forKey: "isAgentEnabled")
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $showHelpSheet) {
                    HelpView()
                }
                .onAppear(perform: checkForMenuBarAgent)
                .environmentObject(viewModel)
                .frame(width: 880, height: 580)
                .fixedSize()
                .toolbar {
                    updateToolbar
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        .commands {
            aboutCommand
            helpCommand
        }
    }
    
    
    private var updateToolbar: some ToolbarContent {
        ToolbarItemGroup {
            Picker("Update Type", selection: $viewModel.selectedTab) {
                Text("􁙌 Latest Release").tag(UpdateType.release)
                Text("􁂶 Latest Snapshot").tag(UpdateType.snapshot)
            }
            ForEach(UpdateAction.allCases, id: \.self) { action in
                Button(action.label) {
                    showAlertFor = action
                }
                .alert(item: $showAlertFor) { action in
                    Alert(title: Text(action.alertTitle),
                          message: Text(action.alertMessage),
                          primaryButton: .destructive(Text(action.primaryButtonText), action: action.action),
                          secondaryButton: .cancel())
                }
            }
        }
    }
    
    private var aboutCommand: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About & Settings") {
                showHelpSheet.toggle()
            }
        }
    }
    
    private var helpCommand: some Commands {
        CommandGroup(replacing: .help) {
            Button("View Guide") {
                showHelpSheet.toggle()
            }
        }
    }
    
    
    private func checkForMenuBarAgent() {
        if isAgentEnabled {
            launchMenuBarAgent()
        }
    }
}

enum UpdateAction: CaseIterable, Identifiable {
    case resetUser, resetGradle, resetWorkspace
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .resetUser: return "􁣔 Reset User"
        case .resetGradle: return "􀻃 Reset Gradle"
        case .resetWorkspace: return "􁌅 Reset Workspaces"
        }
    }
    
    var alertTitle: String {
        switch self {
        case .resetUser: return "Reset User Files?"
        case .resetGradle: return "Reset Gradle Files?"
        case .resetWorkspace: return "Are you sure about this?"
        }
    }
    
    var alertMessage: String {
        switch self {
        case .resetUser:
            return "This will remove all your plugins, backgrounds, templates, user preferences, logs, and the recents list. This action cannot be undone."
        case .resetGradle:
            return "This will reset your Gradle folder. Setup for projects will take longer."
        case .resetWorkspace:
            return "This will delete all of your workspaces. This action cannot be undone."
        }
    }
    
    var primaryButtonText: String {
        switch self {
        case .resetUser, .resetWorkspace: return "Delete"
        case .resetGradle: return "Reset"
        }
    }
    
    var action: () -> Void {
        switch self {
        case .resetUser: return resetUserFiles
        case .resetGradle: return resetGradleFiles
        case .resetWorkspace: return resetWorkspaces
        }
    }
}


struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}

struct HelpView: View {
    @State private var isAgentEnabled: Bool = UserDefaults.standard.bool(forKey: "isAgentEnabled")
    let appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    let appBuild: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack() {
                Text("mUpdater")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                
                Text("Version: \(appVersion) (Build \(appBuild))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Divider()
            
            VStack(alignment: .leading, spacing: 5) {
                Toggle("Enable AutoCheck Agent", isOn: $isAgentEnabled)
                    .onChange(of: isAgentEnabled) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "isAgentEnabled")
                        if newValue {
                            launchMenuBarAgent()
                        } else {
                            demolishMenuBarAgent()
                        }
                    }
                Text("When enabled, this will automatically check for updates in the background.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Divider()
            
            GroupBox() {
                Text("mUpdater is an unofficial tool designed to streamline the process of keeping your MCreator up-to-date. With this tool, you can easily fetch the latest versions, be it a snapshot or a regular release, and apply them to your current installation.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(5)
            }
            .frame(maxWidth: .infinity)
            
            GroupBox() {
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Download Disk Image Only: This option will only download the latest disk image.")
                    Text("2. Full Update: Downloads the disk image, and replaces your current MCreator app.")
                    Text("3. Snapshot vs Regular: Choose between the snapshot ( prerelease) versions or regular releases.")
                    Text("4. Delete Folders: If you encounter issues, this option allows you to delete specific folders to troubleshoot.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(5)
            }
            .frame(maxWidth: .infinity)
            
            GroupBox() {
                Text("For the Full Update option, the app needs to replace the current MCreator app on your system. This action requires administrative privileges to manage disk images and move files. Hence, you'll be prompted to enter your password to grant the necessary permissions.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(5)
            }
            .frame(maxWidth: .infinity)
            
            GroupBox() {
                Text("Always ensure you have backups of your projects and important data before performing updates. While this tool aims to make the process seamless, there's always a risk with software updates.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(5)
            }
            .frame(maxWidth: .infinity)
            
            Text("With love, Will")
                .font(.headline)
        }
        .padding(40)
        .frame(width: 750)
    }
}

enum UpdateType {
    case snapshot, release
}

func resetUserFiles() {
    let paths = [
        "~/.mcreator/plugins",
        "~/.mcreator/backgrounds",
        "~/.mcreator/templates",
        "~/.mcreator/userpreferences",
        "~/.mcreator/logs",
        "~/.mcreator/recentworkspaces"
    ]
    
    deleteFiles(at: paths)
}

func resetGradleFiles() {
    let paths = ["~/.mcreator/gradle"]
    
    deleteFiles(at: paths)
}

func resetWorkspaces() {
    let paths = ["~/MCreatorWorkspaces"]
    
    deleteFiles(at: paths)
}

func deleteFiles(at paths: [String]) {
    let fileManager = FileManager.default
    for path in paths {
        let expandedPath = (path as NSString).expandingTildeInPath
        do {
            try fileManager.removeItem(atPath: expandedPath)
        } catch {
            print("Couldn't delete \(path): \(error)")
        }
    }
}

func launchMenuBarAgent() {
    // Assuming the menu bar agent app is named "mUpdaterMenuBar.app" and is located in the Applications folder
    let agentAppName = "mUpdaterMenuBar"
    if !NSWorkspace.shared.launchApplication(agentAppName) {
        print("Failed to launch \(agentAppName)")
    }
}

func demolishMenuBarAgent() {
    let bundleIdentifier = "mUpdaterMenuBar"
    let task = Process()
    task.launchPath = "/usr/bin/pkill"
    task.arguments = ["-f", bundleIdentifier]
    task.launch()
}
