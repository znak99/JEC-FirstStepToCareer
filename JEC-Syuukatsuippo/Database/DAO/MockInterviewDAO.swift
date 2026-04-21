//
//  MockInterviewDAO.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import RealmSwift
import Foundation

class MockInterviewDAO {
    let realm = try! Realm()
    
    func add(
        companyName: String, interviewTypeIcon: String, totalScore: Int, interviewFeedback: String,
        questions: [String], answers: [String], eyesScores: [Int], faceScores: [Int], answerSpeedScores: [Int]
    ) {
        try! realm.write {
            let interview = MockInterview()
            interview.companyName = companyName
            interview.interviewTypeIcon = interviewTypeIcon
            interview.totalScore = totalScore
            interview.interviewFeedback = interviewFeedback
            for question in questions {
                interview.questions.append(question)
            }
            for answer in answers {
                interview.answers.append(answer)
            }
            for score in eyesScores {
                interview.eyesScores.append(score)
            }
            for score in faceScores {
                interview.faceScores.append(score)
            }
            for score in answerSpeedScores {
                interview.answerSpeedScores.append(score)
            }
            
            realm.add(interview)
        }
    }
    
    func get(byId id: UUID) -> MockInterview? {
        return realm.object(ofType: MockInterview.self, forPrimaryKey: id)
    }
    
    func getAll() -> Results<MockInterview> {
        return realm.objects(MockInterview.self)
    }
    
    func delete(byId id: UUID) {
        let interview = realm.object(ofType: MockInterview.self, forPrimaryKey: id)
        try! realm.write {
            guard let interview else {
                return
            }
            realm.delete(interview)
        }
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
