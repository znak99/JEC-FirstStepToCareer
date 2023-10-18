//
//  HomePage.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import Foundation

enum HomePage {
    case history
    case mockInterview
    case analyze
    
    var description: String {
        switch self {
        case .history:
            return "History"
        case .mockInterview:
            return "Mock Interview"
        case .analyze:
            return "Analyze"
        }
    }
}
