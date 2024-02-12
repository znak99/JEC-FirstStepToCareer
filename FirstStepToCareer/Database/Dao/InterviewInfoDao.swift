//
//  InterviewInfoDao.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import RealmSwift

class InterviewInfoDao {
    let realm = try! Realm()
    
    func save(companyName: String, interviewType: String, companyType: String, careerType: String) {
        self.delete()
        
        try! realm.write {
            let interviewInfo = InterviewInfo()
            interviewInfo.companyName = companyName
            interviewInfo.interviewType = interviewType
            interviewInfo.companyType = companyType
            interviewInfo.careerType = careerType
            
            realm.add(interviewInfo)
        }
    }
    
    func delete() {
        if let interviewInfo = realm.objects(InterviewInfo.self).first {
           try! realm.write {
               realm.delete(interviewInfo)
           }
       }
    }
    
    func read() -> InterviewInfo {
        if let interviewInfo = realm.objects(InterviewInfo.self).first {
           return interviewInfo
        }
        
        return InterviewInfo()
    }
}
