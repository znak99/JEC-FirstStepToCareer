//
//  InterviewInfoDao.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import RealmSwift
import Foundation

class MockInterviewDao {
    let realm = try! Realm()
    
    func add(
        companyName: String,
        interviewTypeIcon: String,
        totalScore: Int,
        interviewFeedback: String,
        questions: [String],
        answers: [String],
        eyesScores: [Int],
        faceScores: [Int],
        answerSpeedScores: [Int]
    ) {
        try! realm.write {
            let mockInterview = MockInterview()
            mockInterview.companyName = companyName
            mockInterview.interviewTypeIcon = interviewTypeIcon
            mockInterview.totalScore = totalScore
            mockInterview.interviewFeedback = interviewFeedback
            for question in questions {
                mockInterview.questions.append(question)
            }
            for answer in answers {
                mockInterview.answers.append(answer)
            }
            for score in eyesScores {
                mockInterview.eyesScores.append(score)
            }
            for score in faceScores {
                mockInterview.faceScores.append(score)
            }
            for score in answerSpeedScores {
                mockInterview.answerSpeedScores.append(score)
            }
            
            realm.add(mockInterview)
        }
    }
    
    func getAll() -> Results<MockInterview> {
        return realm.objects(MockInterview.self)
    }
    
    func get(byId id: UUID) -> MockInterview? {
        return realm.object(ofType: MockInterview.self, forPrimaryKey: id)
    }
    
    func deleteAll() {
        let interviews = realm.objects(MockInterview.self)
        try! realm.write {
            for interview in interviews {
                realm.delete(interview)
            }
        }
    }
}
