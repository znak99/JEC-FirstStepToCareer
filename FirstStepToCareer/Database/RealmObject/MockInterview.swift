//
//  MockInterview.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/25.
//

import RealmSwift
import Foundation

class MockInterview: Object {
    @Persisted var id = UUID()
    @Persisted var companyName = ""
    @Persisted var interviewTypeIcon = ""
    @Persisted var date: Date = Date()
    @Persisted var totalScore: Int = 0
    @Persisted var interviewFeedback = ""
    @Persisted var questions: RealmSwift.List<String> = RealmSwift.List<String>()
    @Persisted var answers: RealmSwift.List<String> = RealmSwift.List<String>()
    @Persisted var eyesScores: RealmSwift.List<Int> = RealmSwift.List<Int>()
    @Persisted var faceScores: RealmSwift.List<Int> = RealmSwift.List<Int>()
    @Persisted var answerSpeedScores: RealmSwift.List<Int> = RealmSwift.List<Int>()
}
