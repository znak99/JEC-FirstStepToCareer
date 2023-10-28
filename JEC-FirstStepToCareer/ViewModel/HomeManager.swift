//
//  HomeManager.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import SwiftUI

class HomeManager: ObservableObject {
    
    // Home
    @Published var isAppReady = false
    @Published var currentPage: HomePage = .mockInterview
    
    // Mock interview
    @Published var companyName = ""
    @Published var isFieldFocused = false
    @Published var currentInterviewType: InterviewType = .newcomer
    @Published var currentCompanyType: CompanyType = .none
    @Published var currentCareerType: CareerType = .none
    @Published var isSaveInterviewInfo = false
    
    // Home header background text
    var bgText: String {
        return currentPage.title.padding(toLength: 5, withPad: "", startingAt: 0)
    }
    
    // Page navigator
    func navigatePage(page: HomePage) {
        if page == currentPage { return }
        
        withAnimation(.easeIn(duration: 0.2)) {
            currentPage = page
        }
    }
    
    // Clear mock interview info's text field
    func clearField() {
        companyName = ""
    }
    
    // Select interview type
    func selectInterviewType(type: InterviewType) {
        if type == currentInterviewType { return }
        
        currentInterviewType = type
    }
    
    // Select company type
    func selectCompanyType(type: CompanyType) {
        if type == currentCompanyType { return }
        
        currentCompanyType = type
    }
    
    // Select career type
    func selectCareerType(type: CareerType) {
        if type == currentCareerType { return }
        
        currentCareerType = type
    }
}
