//
//  HomeManager.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import Foundation

class HomeManager: ObservableObject {
    @Published var isAppReady = false
    @Published var currentPage: HomePage = .mockInterview
    
    var bgText: String {
        return currentPage.description.padding(toLength: 5, withPad: "", startingAt: 0)
    }
}
