//
//  InterviewInfoTemp.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import Foundation

class InterviewInfoTemp {
    static let shared = InterviewInfoTemp()
    
    private init() {}
    
    var companyName: String = ""
    var interviewType: String = ""
    var companyType: String = ""
    var careerType: String = ""
    
    var faceRectangleAvg: CGRect = .zero
    
    var interviewScore: Int = 0
    var interviewFeedback: String = ""
    
    var conversations: [GPTMessage] = []
    
    var eyesScores: [Int] = []
    var faceScores: [Int] = []
    var answerSpeedScores: [Int] = []
    
    func clear() {
        companyName = ""
        interviewType = ""
        companyType = ""
        careerType = ""
        
        faceRectangleAvg = .zero
        
        interviewScore = 0
        interviewFeedback = ""
        
        conversations = []
        
        eyesScores = []
        faceScores = []
        answerSpeedScores = []
    }
    
    func calcInterviewScore() {
        if faceScores.isEmpty || answerSpeedScores.isEmpty {
            print("InterviewInfoTemp - calcInterviewScore")
            print("=> faceScores 혹은 answerSpeedScores 중 빈 배열 존재")
            print("=> interviewScore 계산되지 않음 현재 값 interviewScore: \(interviewScore)")
            return
        }
        
        if eyesScores.isEmpty {
            for score in faceScores {
                var generatedScore = score + Int.random(in: -10...10)
                if generatedScore > 100 {
                    generatedScore = Int.random(in: 90..<100)
                }
                
                eyesScores.append(generatedScore)
            }
        }
        
        let eyesSum = eyesScores.reduce(0, +)
        let eyesAvg = eyesSum / eyesScores.count
        
        let faceSum = faceScores.reduce(0, +)
        let faceAvg = faceSum / faceScores.count
        
        let answerSpeedSum = answerSpeedScores.reduce(0, +)
        let answerSpeedAvg = answerSpeedSum / answerSpeedScores.count
        
        interviewScore = (eyesAvg + faceAvg + answerSpeedAvg) / 3
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
}
