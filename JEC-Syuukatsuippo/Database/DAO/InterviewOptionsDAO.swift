//
//  InterviewOptionsDAO.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import RealmSwift

class InterviewOptionsDAO {
    let realm = try! Realm()
    
    func add(companyName: String, interviewType: String, companyType: String, careerType: String) {
        self.delete()
        
        try! realm.write {
            let interviewOptions = InterviewOptions()
            interviewOptions.companyName = companyName
            interviewOptions.interviewType = interviewType
            interviewOptions.companyType = companyType
            interviewOptions.careerType = careerType
            
            realm.add(interviewOptions)
        }
    }
    
    func get() -> InterviewOptions {
        if let interviewOptions = realm.objects(InterviewOptions.self).first {
           return interviewOptions
        }
        
        return InterviewOptions()
    }
    
    func delete() {
        if let interviewOptions = realm.objects(InterviewOptions.self).first {
           try! realm.write {
               realm.delete(interviewOptions)
           }
       }
    }
}
