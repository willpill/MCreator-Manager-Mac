//
//  mNativeUpdaterApp.swift
//  mNativeUpdater
//
//  Created by Yinwei Z on 10/22/23.
//

import SwiftUI

@main
struct mNativeUpdaterApp: App {
    @State private var doResetRoot = false
    @State private var doResetGradle = false
    @State private var doResetWk = false
    @State private var doResetAll = false
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                  width: 880, height: 580)
                .fixedSize()
                .toolbar {
                    ToolbarItemGroup {
                        Toggle(isOn: $doResetRoot) {
                            Text("Reset User")
                            Image(systemName: "person.circle")
                        }
                        Toggle(isOn: $doResetGradle) {
                            Text("Reset Gradle")
                            Image(systemName: "hammer.circle")
                        }
                        Toggle(isOn: $doResetWk) {
                            Text("Reset Workspaces")
                            Image(systemName: "folder.circle")
                        }
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
    }
    
}
