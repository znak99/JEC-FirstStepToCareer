//
//  SettingsManager.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/15.
//

import Foundation
import SwiftUI
import RealmSwift

class SettingsManager: ObservableObject {
    @Published var isDeleteAllAppDataConfirm = false
}
