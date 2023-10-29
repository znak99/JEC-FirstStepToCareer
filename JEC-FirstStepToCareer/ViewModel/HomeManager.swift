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
    @Published var isShowLoadingIndicator = false
    
    // Mock interview
    @Published var companyName = ""
    @Published var isFieldFocused = false
    @Published var currentInterviewType: InterviewType = .newcomer
    @Published var currentCompanyType: CompanyType = .none
    @Published var currentCareerType: CareerType = .none
    @Published var isSaveInterviewInfo = true
    @Published var isInitializeInterview = false
    @Published var isValidationFailed = false
    @Published var isConnectionFailed = false
    
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
        // Show loading indicator
        isShowLoadingIndicator = true
        
        // Generate random delay time
        let delay = Int.random(in: 100...500)
        
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(delay))) {
            // Check Validation
            if self.companyName.isEmpty || self.currentCompanyType == .none || self.currentCareerType == .none {
                self.isValidationFailed = true
                self.isShowLoadingIndicator = false
                return
            }
            self.isValidationFailed = false

            // Store interview info on db
            if self.isSaveInterviewInfo {
                self.saveInterviewInfo()
            }
            
            // Check connection with server and navigate, hide indicator
            self.checkConnection()
        }
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
                if let interviewInfoObject = interviewInfoObjects.first {
                    interviewInfoObject.companyName = companyName
                    interviewInfoObject.interviewType = currentInterviewType.rawValue
                    interviewInfoObject.companyType = currentCompanyType.rawValue
                    interviewInfoObject.careerType = currentCareerType.rawValue
                    interviewInfoObject.isInterviewInfoSaved = isSaveInterviewInfo
                }
            }
        }
        
        // Update interview info fields
        updateMockInterviewFields()
    }
    
    // Fill mock interview info fields
    func updateMockInterviewFields() {
        let interviewInfoObjects = realm.objects(InterviewInfo.self)
        
        if !interviewInfoObjects.isEmpty {
            if let interviewInfoObject = interviewInfoObjects.first {
                companyName = interviewInfoObject.companyName
                currentInterviewType = InterviewType(rawValue: interviewInfoObject.interviewType)!
                currentCompanyType = CompanyType(rawValue: interviewInfoObject.companyType)!
                currentCareerType = CareerType(rawValue: interviewInfoObject.careerType)!
                isSaveInterviewInfo = interviewInfoObject.isInterviewInfoSaved
            }
        }
    }
    
    // Check network
    func checkConnection() {
        guard let url = AppConstants.requestUrl() else {
            isConnectionFailed = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data else {
                self.isConnectionFailed = true
                return
            }
            
            guard let decodedData = try? JSONDecoder().decode(RootResponse.self, from: data) else {
                self.isConnectionFailed = true
                return
            }
            
            DispatchQueue.main.async {
                if decodedData.message == "root" {
                    self.isConnectionFailed = false
                    
                    // Navigate
                    self.isInitializeInterview = true
                } else {
                    self.isConnectionFailed = true
                }
                
                // Hide loading indicator
                self.isShowLoadingIndicator = false
            }
        }.resume()
    }
}
