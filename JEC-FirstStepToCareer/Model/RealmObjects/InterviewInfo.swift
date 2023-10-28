//
//  InterviewInfo.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/28.
//

import RealmSwift

class InterviewInfo: Object {
    @Persisted var companyName = ""
    @Persisted var interviewType = ""
    @Persisted var companyType = ""
    @Persisted var careerType = ""
    @Persisted var isInterviewInfoSaved = false
}
