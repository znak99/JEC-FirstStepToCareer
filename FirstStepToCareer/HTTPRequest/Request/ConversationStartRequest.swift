//
//  RootResponse.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/29.
//

import Foundation

struct ConversationStartRequest: Encodable {
    let company_name: String
    let interview_type: String
    let company_type: String
    let career_type: String
}
