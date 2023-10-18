//
//  HomePage.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import SwiftUI

enum HomePage {
    case history
    case mockInterview
    case analyze
    
    var title: String {
        switch self {
        case .history:
            return "History"
        case .mockInterview:
            return "Mock Interview"
        case .analyze:
            return "Analyze"
        }
    }
    
    var icon: String {
        switch self {
        case .history:
            return "HistoryIcon"
        case .mockInterview:
            return "MockInterviewIcon"
        case .analyze:
            return "AnalyzeIcon"
        }
    }
    
    var description: String {
        switch self {
        case .history:
            return "過去に行った模擬面接のフィードバックを見返します"
        case .mockInterview:
            return "簡単な情報を入力して模擬面接を行います"
        case .analyze:
            return "過去に行った模擬面接を元に分析した結果を確認します"
        }
    }
}
