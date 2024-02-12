//
//  InterviewType.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import Foundation

enum InterviewType: String {
    case newcomer = "新卒"
    case experienced = "中途"
    
    var icon: String {
        switch self {
        case .newcomer:
            return "graduationcap.fill"
        case .experienced:
            return "suitcase.fill"
        }
    }
}
