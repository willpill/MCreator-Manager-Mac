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
    @StateObject var viewModel = UpdaterViewModel()
    @State private var showUserFilesConfirmation = false
    @State private var showGradleFilesConfirmation = false
    @State private var showWorkspaceConfirmation = false
    @State private var selectedTab: UpdateType = .release
    
    var body: some Scene {
        WindowGroup {
            ContentView()
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
                            Text("􁣔 Reset User Files")
                        }
                        .alert(isPresented: $showUserFilesConfirmation) {
                            Alert(title: Text("Reset all User Files?"),
                                  message: Text("This will remove all your plugins, backgrounds, templates, user preferences, logs, and the recents list. This action cannot be undone."),
                                  primaryButton: .destructive(Text("Reset"), action: resetUserFiles),
                                  secondaryButton: .cancel())
                        }
                        
                        Button(action: {
                            showGradleFilesConfirmation.toggle()
                        }) {
                            Text("􀻃 Reset Gradle Files")
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
                            Text("􁌅 Delete All Workspaces")
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
