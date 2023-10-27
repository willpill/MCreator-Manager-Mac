//
//  UpdaterViewModel.swift
//  mNativeUpdater
//
//  Created by Yinwei Z on 10/26/23.
//

import Combine
import SwiftUI

class UpdaterViewModel: ObservableObject {
    @Published var selectedTab: UpdateType = .release
}
