//
//  ContentView.swift
//  mUpdater
//
//  Created by Yinwei Z on 10/22/23.
//

import SwiftUI
import AppKit
import Network

struct ContentView: View {
    @EnvironmentObject var viewModel: UpdaterViewModel
    @State var log: String = ""
    @State var progressValue: Double = 0.0
    @State var isUpdating: Bool = false
    @State var updateComplete: Bool = false
    @State var isConnected: Bool = false
    @State private var isCheckingForUpdate: Bool = true
    @State private var isBuffering: Bool = false
    @State private var isUpdateAvailable: Bool? = nil
    @State private var localVersion: String = ""
    
    var body: some View {
        ZStack {
            BlurredView(material: .sidebar)
            VStack(alignment: .leading, spacing: 20) {
                Spacer(minLength: 15)
                HStack {
                    Image("mctlogo")
                        .resizable()
                        .frame(width: 40, height: 40)
                    VStack (alignment: .leading){
                        Text("mUpdater")
                            .font(.title2)
                            .bold()
                        Text("Made by willpill. Not affiliated with Pylo.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                ScrollView {
                    ScrollViewReader { reader in
                        Text(log)
                            .frame(maxWidth: .infinity, minHeight: 401, alignment: .topLeading)
                            .padding()
                            .font(.system(.body, design: .monospaced))
                            .id("logText")
                            .onChange(of: log) { newValue, _ in
                                withAnimation {
                                    reader.scrollTo("logText", anchor: .bottom)
                                }
                            }
                    }
                    .background(Color.clear)
                }
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(NSColor.systemGray).opacity(0.25))
                )
                .overlay(
                    Group {
                        if log.isEmpty {
                            HStack {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .symbolEffect(.variableColor)
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Logs will display here")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                    .bold()
                            }
                        } else {
                            EmptyView()
                        }
                    }
                )
                
                if isUpdating && !updateComplete {
                    ProgressView(value: progressValue, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.accentColor))
                        .frame(maxWidth: .infinity, minHeight: 28)
                } else if isCheckingForUpdate {
                    Button(action: {
                        checkForUpdates()
                    }) {
                        HStack(){
                            Image(systemName: "target")
                                .opacity(isBuffering ? 1.0 : 0.0)
                                .symbolEffect(.variableColor)
                            Text(isBuffering ? "Checking for Update" : "Check for Update")
                                
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
                } else if updateComplete {
                    Button(action: {}) {
                        Text("Update Complete")
                        .frame(maxWidth: .infinity)}
                    .controlSize(.large)
                    .disabled(true)
                } else if isUpdateAvailable != nil {
                    HStack (){
                        Button(action: {
                            startUpdateProcess()
                        }) {
                            Text("􀰾 Update Now")
                                .frame(maxWidth: .infinity)
                            
                        }
                        .keyboardShortcut(.defaultAction)
                        Button(action: {
                            checkForUpdates()
                        }) {
                            Text("􀅈 Recheck")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .controlSize(.large)
                } else if !isConnected {
                    Button(action: {}) {
                        Text("No Connection")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .disabled(true)
                }
            }
            .padding()
        }
        .ignoresSafeArea()
        .onAppear(perform: checkNetworkConnection)
    }
    
    func checkNetworkConnection() {
        let networkChecker = NetworkCheck()
        networkChecker.startMonitoring { connectionStatus in
            isConnected = connectionStatus
            networkChecker.stopMonitoring()
        }
    }
    
    func checkForUpdates() {
        isBuffering = true
        isCheckingForUpdate = true
        
        guard let path = Bundle(url: URL(fileURLWithPath: "/Applications/MCreator.app")),
              let bundleVersion = path.infoDictionary?["CFBundleVersion"] as? String else {
            log.append("MCreator.app not found in Applications.\n")
            isCheckingForUpdate = false
            return
        }
        
        localVersion = bundleVersion
        
        let fetchURL = viewModel.selectedTab == .release ?
        "https://api.github.com/repos/MCreator/MCreator/releases/latest" :
        "https://api.github.com/repos/MCreator/MCreator/releases?per_page=5"
        
        fetchAndUpdate(fetchURL)
    }
    
    func fetchAndUpdate(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                if viewModel.selectedTab == .release, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let tagName = json["tag_name"] as? String {
                    DispatchQueue.main.async {
                        handleUpdateCheck(tagName: tagName)
                    }
                } else if let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    for json in jsonArray where json["prerelease"] as? Bool == true {
                        if let tagName = json["tag_name"] as? String {
                            DispatchQueue.main.async {
                                handleUpdateCheck(tagName: tagName, isSnapshot: true)
                            }
                            break
                        }
                    }
                }
            }
        }
    }
    
    func handleUpdateCheck(tagName: String, isSnapshot: Bool = false) {
        isCheckingForUpdate = false
        
        let versionMessage = isSnapshot ?
        "The newest snapshot available is \(tagName).\n" :
        "A new release \(tagName) is available. Installed version is \(localVersion).\n"
        
        let upToDateMessage = isSnapshot ?
        "The newest snapshot available is \(tagName).\n" :
        "MCreator is up to date with version \(localVersion). However, there may still be a newer patch update (\(tagName)) available.\n"
        
        if tagName.prefix(5) != localVersion.prefix(5) {
            log.append(versionMessage)
            isUpdateAvailable = true
        } else {
            log.append(upToDateMessage)
            isUpdateAvailable = false
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
