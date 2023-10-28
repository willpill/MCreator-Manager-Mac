//
//  ContentView.swift
//  mNativeUpdater
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
                } else if !isUpdating && !updateComplete && isConnected {
                    Button(action: {
                        startUpdateProcess()
                    }) {
                        Text("􀊕 Start Update")
                            .frame(maxWidth: .infinity)
                    }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
                } else if updateComplete {
                    Button(action: {}) {
                        Text("Update Complete")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .disabled(true)
                } else if !isConnected {
                    Button(action: {}) {
                        Text("􀙈 No Connection")
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
