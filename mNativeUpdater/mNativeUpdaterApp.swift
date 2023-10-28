//
//  mNativeUpdaterApp.swift
//  mNativeUpdater
//
//  Created by Yinwei Z on 10/22/23.
//

import SwiftUI
import Foundation

@main
struct mNativeUpdaterApp: App {
    @State private var showHelpView = false
    @StateObject var viewModel = UpdaterViewModel()
    @State private var showUserFilesConfirmation = false
    @State private var showGradleFilesConfirmation = false
    @State private var showWorkspaceConfirmation = false
    @State private var selectedTab: UpdateType = .release
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $showHelpView) {
                                    HelpView()
                                }
                .environmentObject(viewModel)
                .frame(width: 880, height: 580)
                .fixedSize()
                .toolbar {
                    ToolbarItemGroup {
                        
                        Picker("Update Type", selection: $viewModel.selectedTab) {
                            Text("􁙌 Latest Release").tag(UpdateType.release)
                            Text("􁂶 Latest Snapshot").tag(UpdateType.snapshot)
                        }
                        
                        Button(action: {
                            showUserFilesConfirmation.toggle()
                        }) {
                            Text("􁣔 Reset User")
                        }
                        .alert(isPresented: $showUserFilesConfirmation) {
                            Alert(title: Text("Reset User Files?"),
                                  message: Text("This will remove all your plugins, backgrounds, templates, user preferences, logs, and the recents list. This action cannot be undone."),
                                  primaryButton: .destructive(Text("Reset"), action: resetUserFiles),
                                  secondaryButton: .cancel())
                        }
                        
                        Button(action: {
                            showGradleFilesConfirmation.toggle()
                        }) {
                            Text("􀻃 Reset Gradle")
                        }
                        .alert(isPresented: $showGradleFilesConfirmation) {
                            Alert(title: Text("Reset Gradle Files?"),
                                  message: Text("This will reset your Gradle folder. Setup for projects will take longer."),
                                  primaryButton: .destructive(Text("Reset"), action: resetGradleFiles),
                                  secondaryButton: .cancel())
                        }
                        
                        Button(action: {
                            showWorkspaceConfirmation.toggle()
                        }) {
                            Text("􁌅 Reset Workspaces")
                        }
                        .alert(isPresented: $showWorkspaceConfirmation) {
                            Alert(title: Text("Are you sure about this?"),
                                  message: Text("This will delete all of your workspaces. This action cannot be undone."),
                                  primaryButton: .destructive(Text("Delete"), action: resetWorkspaces),
                                  secondaryButton: .cancel())
                        }
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                            Button("About mUpdater") {
                                showHelpView.toggle()
                            }
                        }
            CommandGroup(replacing: .help) {
                            Button("View Guide") {
                                showHelpView.toggle()
                            }
                    }
                }
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}

struct HelpView: View {
    let appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let appBuild: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("mUpdater")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version: \(appVersion) (Build \(appBuild))")
                            .font(.subheadline)
                            .foregroundColor(.gray)

            GroupBox() {
                Text("The MCreator Updater is designed to streamline the process of keeping your MCreator software up-to-date. With this tool, you can easily fetch the latest versions, be it a snapshot or a regular release, and apply them to your current installation.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(5)
            }
            .frame(width: 700, height: 90)

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
            .frame(width: 700, height: 130)

            GroupBox() {
                Text("For the Full Update option, the app needs to replace the current MCreator software on your system. This action requires administrative privileges to manage disk images and move files. Hence, you'll be prompted to enter your password to grant the necessary permissions.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(5)
            }
            .frame(width: 700, height: 90)

            GroupBox() {
                Text("Always ensure you have backups of your projects and important data before performing updates. While this tool aims to make the process seamless, there's always a risk with software updates.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(5)
            }
            .frame(width: 700, height: 70)

            Text("With love, Will")
                .font(.headline)
        }
        .padding()
        .frame(width: 750, height: 525)
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
        if fileManager.fileExists(atPath: expandedPath) {
            do {
                try fileManager.removeItem(atPath: expandedPath)
            } catch {
                print("Cant delete \(path): \(error)")
            }
        }
    }
}
