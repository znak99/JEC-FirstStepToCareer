//
//  HomeManager.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import SwiftUI
import RealmSwift

class HomeManager: ObservableObject {
    
    // Home
    let realm = try! Realm()
    
    @Published var isAppReady = false
    @Published var currentPage: HomePage = .mockInterview
    
    // Mock interview
    @Published var companyName = ""
    @Published var isFieldFocused = false
    @Published var currentInterviewType: InterviewType = .newcomer
    @Published var currentCompanyType: CompanyType = .none
    @Published var currentCareerType: CareerType = .none
    @Published var isSaveInterviewInfo = true
    @Published var isInitializeInterview = false
    @Published var isValidationFailed = false
    
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
    
    // Navigate to initialize mock interview view
    func initializeMockInterview() {
        // Check Validation
        if companyName.isEmpty || currentCompanyType == .none || currentCareerType == .none {
            isValidationFailed = true
            return
        }
        isValidationFailed = false
        
        // Store interview info on db
        if isSaveInterviewInfo {
            saveInterviewInfo()
        }
        
        // Show Indicator
        
        // Check connection with server
        
        // Navigate
        isInitializeInterview = true
    }
    
    // Store interview info on realm
    func saveInterviewInfo() {
        // Check have created interview info object before
        let interviewInfoObjects = realm.objects(InterviewInfo.self)
        
        if interviewInfoObjects.isEmpty {
            // Add new object
            try! realm.write {
                let interviewInfo = InterviewInfo()
                interviewInfo.companyName = companyName
                interviewInfo.interviewType = currentInterviewType.rawValue
                interviewInfo.companyType = currentCompanyType.rawValue
                interviewInfo.careerType = currentCareerType.rawValue
                interviewInfo.isInterviewInfoSaved = isSaveInterviewInfo
                
                realm.add(interviewInfo)
            }
        } else {
            // Update the properties of the existing object
            try! realm.write {
                if let existingInfo = interviewInfoObjects.first {
                    existingInfo.companyName = companyName
                    existingInfo.interviewType = currentInterviewType.rawValue
                    existingInfo.companyType = currentCompanyType.rawValue
                    existingInfo.careerType = currentCareerType.rawValue
                    existingInfo.isInterviewInfoSaved = isSaveInterviewInfo
                }
            }
        }
    }
}
