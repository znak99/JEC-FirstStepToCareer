//
//  HomeManager.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import SwiftUI

class HomeManager: ObservableObject {
    @Published var isAppReady = false
    @Published var currentPage: HomePage = .mockInterview
    
    var bgText: String {
        return currentPage.title.padding(toLength: 5, withPad: "", startingAt: 0)
    }
    
    func navigatePage(page: HomePage) {
        if page == currentPage {
            return
        }
        
        withAnimation(.easeIn(duration: 0.2)) {
            currentPage = page
        }
    }
}
