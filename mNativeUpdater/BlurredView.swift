//
//  BlurredView.swift
//  mNativeUpdater
//
//  Created by Yinwei Z on 10/22/23.
//

import SwiftUI
import AppKit

struct BlurredView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}
