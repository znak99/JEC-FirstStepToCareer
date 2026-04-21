//
//  HomeManager.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import Foundation
import SwiftUI
import Combine
import Speech
import AVFoundation

class HomeManager: ObservableObject {
    // MARK: - Home properties
    @Published var isAppLoading = true
    
    @Published var currentPage: HomePage = .mockInterview
    
    @Published var pageSwipeOffset: CGSize = .zero
    
    @Published var isShowLoadingIndicator = false
    
    @Published var isNavigateToInterviewView = false
    
    var bgText: String {
        return currentPage.title.padding(toLength: 5, withPad: "", startingAt: 0)
    }
    
    // MARK: - History properties
    @Published var mockInterviews: [MockInterview] = []
    
    // MARK: - Interview properties
    @Published var currentCompanyName = ""
    @Published var currentInterviewType: InterviewType = .newcomer
    @Published var currentCompanyType: CompanyType = .none
    @Published var currentCareerType: CareerType = .none
    
    @Published var isSaveInterviewOptions: Bool = true
    
    @Published var isValidationFailed = false
    @Published var isAuthorizationDenied = false
    
    @Published var isShowPermissionCaution = false
    
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Analyze properties
    @Published var isInterviewDataEmpty: Bool = false
    @Published var isLoadGraphData: Bool = true
    
    @Published var eyesTotalAvgScore = 0
    @Published var faceTotalAvgScore = 0
    @Published var answerSpeedTotalAvgScore = 0
    
    @Published var eyesGraphData: [GraphData] = []
    @Published var faceGraphData: [GraphData] = []
    @Published var answerSpeedGraphData: [GraphData] = []
    
    // MARK: - DAO
    private var mockInterviewDao = MockInterviewDAO()
    private var interviewOptionsDao = InterviewOptionsDAO()
    
    // MARK: - Home functions
    func swipePage(distance: Double) {
        withAnimation(.easeIn(duration: 0.2)) {
            switch currentPage {
            case .history:
                currentPage = distance > 0 ? .history : .mockInterview
            case .mockInterview:
                currentPage = distance > 0 ? .history : .analyze
            case .analyze:
                currentPage = distance > 0 ? .mockInterview : .analyze
            }
        }
    }
    
    func navigatePage(to page: HomePage) {
        if page == currentPage { return }
        
        withAnimation(.easeIn(duration: 0.2)) {
            currentPage = page
        }
    }
    
    // MARK: - History functions
    func getInterviews() {
        mockInterviews = Array(mockInterviewDao.getAll()).reversed()
    }
    
    // MARK: - Interview functions
    func clearCompanyNameField() {
        currentCompanyName = ""
    }
    
    func selectInterviewType(type: InterviewType) {
        if type == currentInterviewType { return }
        
        currentInterviewType = type
    }
    
    func selectCompanyType(type: CompanyType) {
        if type == currentCompanyType { return }
        
        currentCompanyType = type
    }
    
    func selectCareerType(type: CareerType) {
        if type == currentCareerType { return }
        
        currentCareerType = type
    }
    
    func checkInterviewOptions() {
        let interviewOptions = interviewOptionsDao.get()
        
        currentCompanyName = interviewOptions.companyName
        currentInterviewType = InterviewType(rawValue: interviewOptions.interviewType) ?? .newcomer
        currentCompanyType = CompanyType(rawValue: interviewOptions.companyType) ?? .none
        currentCareerType = CareerType(rawValue: interviewOptions.careerType) ?? .none
    }
    
    func submitInterviewInfo() {
        if isAuthorizationDenied {
            isShowPermissionCaution = true
            return
        }
        
        InterviewInfoTemp.shared.clear()
        
        isShowPermissionCaution = false
        
        isValidationFailed = false
        
        isShowLoadingIndicator = true
        
        let delay = Int.random(in: 300...600)
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(delay))) {
            if self.currentCompanyName.isEmpty || self.currentCompanyType == .none || self.currentCareerType == .none {
                self.isValidationFailed = true
                self.isShowLoadingIndicator = false
                return
            }
            
            if self.isSaveInterviewOptions {
                self.interviewOptionsDao.add(companyName: self.currentCompanyName,
                                             interviewType: self.currentInterviewType.rawValue,
                                             companyType: self.currentCompanyType.rawValue,
                                             careerType: self.currentCareerType.rawValue)
            }
            
            InterviewInfoTemp.shared.companyName = self.currentCompanyName
            InterviewInfoTemp.shared.interviewType = self.currentInterviewType.rawValue
            InterviewInfoTemp.shared.companyType = self.currentCompanyType.rawValue
            InterviewInfoTemp.shared.careerType = self.currentCareerType.rawValue
            
            self.isValidationFailed = false
            self.isShowLoadingIndicator = false
            
            self.isNavigateToInterviewView = true
        }
    }
    
    func requestSpeechAuthorization() {
        print("HomeManager - requestSpeechAuthorization")
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorization 허용")
            case .denied:
                print("Speech recognition authorization 거부")
                self.isAuthorizationDenied = true
            case .restricted:
                print("Speech recognition 제한된 디바이스")
                self.isAuthorizationDenied = true
            case .notDetermined:
                print("Speech recognition authorization 여부 확인되지 않음")
            @unknown default:
                fatalError("Unhandled case")
            }
        }
    }
    
    func requestCameraAuthorization() {
        print("HomeManager - requestCameraAuthorization")
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                print("Camera authorization 허용")
            } else {
                print("Camera authorization 거부")
                self.isAuthorizationDenied = true
            }
        }
    }
    
    func requestMicrophoneAuthorization() {
        print("HomeManager - requestMicrophoneAuthorization")
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            if granted {
                print("Microphone authorization 허용")
            } else {
                print("Microphone authorization 거부")
                self.isAuthorizationDenied = true
            }
        }
    }
    
    // MARK: - Analyze functions
    func checkInterviewDataEmpty() {
        let interviews = Array(mockInterviewDao.getAll())
        
        if interviews.count == 0 {
            isInterviewDataEmpty = true
            return
        } else {
            isInterviewDataEmpty = false
        }
    }
    
    func clearGraphData() {
        eyesTotalAvgScore = 0
        faceTotalAvgScore = 0
        answerSpeedTotalAvgScore = 0
        
        eyesGraphData = []
        faceGraphData = []
        answerSpeedGraphData = []
    }
    
    func calcAnalyzeData() {
        let interviews = Array(mockInterviewDao.getAll())
        
        if interviews.count == 0 {
            isInterviewDataEmpty = true
            return
        }
        isInterviewDataEmpty = false
        
        calcTotalAvgScores(interviews: interviews)
        calcGraphData(category: "eyes", interviews: interviews)
        calcGraphData(category: "face", interviews: interviews)
        calcGraphData(category: "answerSpeed", interviews: interviews)
    }
    
    func calcTotalAvgScores(interviews: [MockInterview]) {
        var eyes = 0
        var face = 0
        var answerSpeed = 0
        
        for interview in interviews {
            if interview.eyesScores.sum() == 0 || interview.faceScores.sum() == 0 || interview.answerSpeedScores.sum() == 0 {
                continue
            }
            
            eyes += interview.eyesScores.sum() / interview.eyesScores.count
            face += interview.faceScores.sum() / interview.faceScores.count
            answerSpeed += interview.answerSpeedScores.sum() / interview.answerSpeedScores.count
        }
        
        let count = interviews.count
        
        self.eyesTotalAvgScore = eyes / count
        self.faceTotalAvgScore = face / count
        self.answerSpeedTotalAvgScore = answerSpeed / count
    }
    
    func calcGraphData(category: String, interviews: [MockInterview]) {
        var sums: [Int] = [0, 0, 0, 0, 0, 0, 0]
        
        for interview in interviews {
            for i in 0..<7 {
                if category == "eyes" {
                    sums[i] += interview.eyesScores[i]
                } else if category == "face" {
                    sums[i] += interview.faceScores[i]
                } else if category == "answerSpeed" {
                    sums[i] += interview.answerSpeedScores[i]
                }
            }
        }
        
        var avgs: [Int] = []
        
        for sum in sums {
            avgs.append(sum / interviews.count)
        }
        
        var idx = 0
        for avg in avgs {
            if category == "eyes" {
                eyesGraphData.append(GraphData(count: "\(idx + 1)番目", score: avg))
            } else if category == "face" {
                faceGraphData.append(GraphData(count: "\(idx + 1)番目", score: avg))
            } else if category == "answerSpeed" {
                answerSpeedGraphData.append(GraphData(count: "\(idx + 1)番目", score: avg))
            }
            idx += 1
        }
    }
    
    // MARK: - Test
    func addDummyMockInterviewData() {
        mockInterviewDao.add(companyName: "Example Interview Data",
                             interviewTypeIcon: InterviewType.newcomer.icon,
                             totalScore: Int.random(in: 10...90),
                             interviewFeedback: "Example Feedback",
                             questions: ["Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q7"],
                             answers: ["A1", "A2", "A3", "A4", "A5", "A6", "A7"],
                             eyesScores: [
                                Int.random(in: 10...90), Int.random(in: 10...90),
                                Int.random(in: 10...90), Int.random(in: 10...90),
                                Int.random(in: 10...90), Int.random(in: 10...90), Int.random(in: 10...90)
                             ],
                             faceScores: [
                                Int.random(in: 10...90), Int.random(in: 10...90),
                                Int.random(in: 10...90), Int.random(in: 10...90),
                                Int.random(in: 10...90), Int.random(in: 10...90), Int.random(in: 10...90)
                             ],
                             answerSpeedScores: [
                                Int.random(in: 10...90), Int.random(in: 10...90),
                                Int.random(in: 10...90), Int.random(in: 10...90),
                                Int.random(in: 10...90), Int.random(in: 10...90), Int.random(in: 10...90)
                             ])
        
        isLoadGraphData = true
    }
    
    func deleteAllAppData() {
        mockInterviewDao.deleteAll()
        isLoadGraphData = true
    }
}
