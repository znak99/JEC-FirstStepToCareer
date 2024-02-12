//
//  HomeManager.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import SwiftUI

class HomeManager: ObservableObject {
    // Home View
    @Published var isAppReady = false
    
    @Published var currentPage: HomePage = .mockInterview
    @Published var pageSwipeOffset: CGSize = .zero
    
    @Published var isShowLoadingIndicator = false
    
    @Published var isNavigateToMockInterviewView = false
    
    // History
    @Published var mockInterviews: [MockInterview] = []
    
    // Mock Interview Page
    @Published var currentCompanyName = ""
    @Published var currentInterviewType: InterviewType = .newcomer
    @Published var currentCompanyType: CompanyType = .none
    @Published var currentCareerType: CareerType = .none
    
    @Published var isSaveInterviewInfo = true
    
    @Published var isValidationFailed = false
    @Published var isConnectionFailed = false
    @Published var isUnknownError = false
    
    // Analyze
    @Published var eyesTotalAvgScore = 0
    @Published var faceTotalAvgScore = 0
    @Published var answerSpeedTotalAvgScore = 0
    
    @Published var eyesData: [AnalyzeData] = []
    @Published var faceData: [AnalyzeData] = []
    @Published var answerSpeedData: [AnalyzeData] = []
    
    @Published var isNeedToLoadData = true
    
    @Published var isNoData = false
    
    private var mockInterviewDao = MockInterviewDao()
    private var interviewInfoDao = InterviewInfoDao()
    
    var bgText: String {
        return currentPage.title.padding(toLength: 5, withPad: "", startingAt: 0)
    }
    
    func getInterviewHistory() {
        mockInterviews = Array(mockInterviewDao.getAll()).reversed()
    }
    
    func swipePage(swipeDistance: Double) {
        var isRight: Bool?
        
        if swipeDistance < 0 {
            isRight = false
        } else if swipeDistance > 0 {
            isRight = true
        }
        
        guard let isRight else { return }
        
        withAnimation(.easeIn(duration: 0.2)) {
            switch currentPage {
            case .history:
                currentPage = isRight ? .history : .mockInterview
            case .mockInterview:
                currentPage = isRight ? .history : .analyze
            case .analyze:
                currentPage = isRight ? .mockInterview : .analyze
            }
        }
        
        print("HomeManager-swipePage 현재홈화면: \(currentPage.title)")
    }
    
    func navigatePage(page: HomePage) {
        if page == currentPage { return }
        
        withAnimation(.easeIn(duration: 0.2)) {
            currentPage = page
        }
    }
    
    func clearField() {
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
    
    func prepareInterview() {
        isShowLoadingIndicator = true
        
        let delay = Int.random(in: 100...500)
        
        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(delay))) {
            if self.currentCompanyName.isEmpty || self.currentCompanyType == .none || self.currentCareerType == .none {
                self.isValidationFailed = true
                self.isShowLoadingIndicator = false
                return
            }
            self.isValidationFailed = false
            self.isConnectionFailed = false
            self.isUnknownError = false
            
            if self.isSaveInterviewInfo {
                self.interviewInfoDao.save(companyName: self.currentCompanyName,
                                           interviewType: self.currentInterviewType.rawValue,
                                           companyType: self.currentCompanyType.rawValue,
                                           careerType: self.currentCareerType.rawValue)
            }
            self.checkConnection()
        }
    }
    
    func checkConnection() {
        HTTPRequest.shared.get(type: RootResponse.self) { data in
            guard let data else {
                self.isConnectionFailed = true
                self.isShowLoadingIndicator = false
                return
            }
            
            if data.message == "root" {
                MockInterviewInfo.shared.initialize()
                MockInterviewInfo.shared.companyName = self.currentCompanyName
                MockInterviewInfo.shared.companyType = self.currentCompanyType.rawValue
                MockInterviewInfo.shared.interviewType = self.currentInterviewType.rawValue
                MockInterviewInfo.shared.careerType = self.currentCareerType.rawValue
                
                self.isConnectionFailed = false
                self.isNavigateToMockInterviewView = true
            } else {
                self.isUnknownError = true
            }
            
            self.isShowLoadingIndicator = false
        }
    }
    
    func interviewInfoFieldInit() {
        let info = interviewInfoDao.read()
        self.currentCompanyName = info.companyName
        self.currentInterviewType = InterviewType(rawValue: info.interviewType) ?? .newcomer
        self.currentCompanyType = CompanyType(rawValue: info.companyType) ?? .none
        self.currentCareerType = CareerType(rawValue: info.careerType) ?? .none
    }
    
    func formatDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        return dateFormatter.string(from: date)
    }
    
    func formatDateWithDay(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd (E)"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        
        return dateFormatter.string(from: date)
    }
    
    func initInfo() {
        mockInterviewDao.add(companyName: "日本電子株式会社",
                             interviewTypeIcon: InterviewType.newcomer.icon,
                             totalScore: 57,
                             interviewFeedback: "Example Feedback",
                             questions: ["Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q7"],
                             answers: ["A1", "A2", "A3", "A4", "A5", "A6", "A7"],
                             eyesScores: [78, 89, 49, 42, 34, 38, 51],
                             faceScores: [33, 54, 51, 58, 43, 44, 49],
                             answerSpeedScores: [34, 44, 55, 55, 25, 39, 69])
    }
    
    func getTotalAvgScores() {
        let interviews = Array(mockInterviewDao.getAll())
        
        if interviews.count == 0 {
            isNoData = true
            return
        }
        
        isNoData = false
        
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
        
        self.eyesTotalAvgScore = eyes / interviews.count
        self.faceTotalAvgScore = face / interviews.count
        self.answerSpeedTotalAvgScore = answerSpeed / interviews.count
    }
    
    func getGraphData() {
        let interviews = Array(mockInterviewDao.getAll())
        
        if interviews.count == 0 {
            isNoData = true
            return
        }
        
        print(interviews.count)
        
        isNoData = false
        
        getEyesGraphData(interviews: interviews)
        getFaceGraphData(interviews: interviews)
        getAnswerSpeedGraphData(interviews: interviews)
        
        isNeedToLoadData = false
    }
    
    func getEyesGraphData(interviews: [MockInterview]) {
        var sums: [Int] = [0, 0, 0, 0, 0, 0, 0]
        
        for interview in interviews {
            for i in 0..<7 {
                sums[i] += interview.eyesScores[i]
            }
        }
        
        var avgs: [Int] = []
        
        for sum in sums {
            avgs.append(sum / interviews.count)
        }
        
        var idx = 0
        for avg in avgs {
            eyesData.append(AnalyzeData(count: "\(idx + 1)番目", score: avg))
            idx += 1
        }
    }
    
    func getFaceGraphData(interviews: [MockInterview]) {
        var sums: [Int] = [0, 0, 0, 0, 0, 0, 0]
        
        for interview in interviews {
            for i in 0..<7 {
                sums[i] += interview.faceScores[i]
            }
        }
        
        var avgs: [Int] = []
        
        for sum in sums {
            avgs.append(sum / interviews.count)
        }
        
        var idx = 0
        for avg in avgs {
            faceData.append(AnalyzeData(count: "\(idx + 1)番目", score: avg))
            idx += 1
        }
    }
    
    func getAnswerSpeedGraphData(interviews: [MockInterview]) {
        var sums: [Int] = [0, 0, 0, 0, 0, 0, 0]
        
        for interview in interviews {
            for i in 0..<7 {
                sums[i] += interview.answerSpeedScores[i]
            }
        }
        
        var avgs: [Int] = []
        
        for sum in sums {
            avgs.append(sum / interviews.count)
        }
        
        var idx = 0
        for avg in avgs {
            answerSpeedData.append(AnalyzeData(count: "\(idx + 1)番目", score: avg))
            idx += 1
        }
    }
    
    func clearAnalyzedData() {
        eyesTotalAvgScore = 0
        faceTotalAvgScore = 0
        answerSpeedTotalAvgScore = 0
        
        eyesData = []
        faceData = []
        answerSpeedData = []
    }
}
