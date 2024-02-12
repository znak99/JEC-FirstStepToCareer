//
//  InterviewInfoModel.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import RealmSwift

class InterviewInfo: Object {
    @Persisted var companyName = ""
    @Persisted var interviewType = ""
    @Persisted var companyType = ""
    @Persisted var careerType = ""
}
