//
//  MockInterviewInfo.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import Foundation
import SwiftUI

class MockInterviewInfo {
    
    static let shared = MockInterviewInfo()
    
    private init() {}
    
    var companyName: String = ""
    var interviewType: String = ""
    var companyType: String = ""
    var careerType: String = ""
    
    var faceTopCoordinateXAvg: Int = 0
    var faceTopCoordinateYAvg: Int = 0
    var faceLeftCoordinateXAvg: Int = 0
    var faceLeftCoordinateYAvg: Int = 0
    var faceRightCoordinateXAvg: Int = 0
    var faceRightCoordinateYAvg: Int = 0
    var faceBottomCoordinateXAvg: Int = 0
    var faceBottomCoordinateYAvg: Int = 0
    
    var leftEyeXAvg: Int = 0
    var leftEyeYAvg: Int = 0
    
    var rightEyeXAvg: Int = 0
    var rightEyeYAvg: Int = 0
    
    var mockInterviewScore: Int = 0
    
    var interviewStoryFeedback: String = ""
    
    var systemMessage: String = ""
    var assistantMessages: [String] = []
    var userMessages: [String] = []
    
    var eyesScores: [Int] = []
    var faceScores: [Int] = []
    var answerSpeedScores: [Int] = []
    
    func calcTotalScore() {
        if eyesScores.count == 0 || faceScores.count == 0 {
            return
        }
        let eyesSum = eyesScores.reduce(0, +)
        let eyesAvg = eyesSum / eyesScores.count
        
        let faceSum = faceScores.reduce(0, +)
        let faceAvg = faceSum / faceScores.count
        
        let answerSpeedSum = answerSpeedScores.reduce(0, +)
        let answerSpeedAvg = answerSpeedSum / answerSpeedScores.count
        
        mockInterviewScore = (eyesAvg + faceAvg + answerSpeedAvg) / 3
    }
    
    func initialize() {
        companyName = ""
        interviewType = ""
        companyType = ""
        careerType = ""
        
        faceTopCoordinateXAvg = 0
        faceTopCoordinateYAvg = 0
        faceLeftCoordinateXAvg = 0
        faceLeftCoordinateYAvg = 0
        faceRightCoordinateXAvg = 0
        faceRightCoordinateYAvg = 0
        faceBottomCoordinateXAvg = 0
        faceBottomCoordinateYAvg = 0
        
        leftEyeXAvg = 0
        leftEyeYAvg = 0
        
        rightEyeXAvg = 0
        rightEyeYAvg = 0
        
        mockInterviewScore = 0
        
        interviewStoryFeedback = ""
        
        systemMessage = ""
        assistantMessages = []
        userMessages = []
        
        eyesScores = []
        faceScores = []
        answerSpeedScores = []
    }
}
