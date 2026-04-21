//
//  InterviewOption.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import RealmSwift

class InterviewOptions: Object {
    @Persisted var companyName = ""
    @Persisted var interviewType = ""
    @Persisted var companyType = ""
    @Persisted var careerType = ""
}
