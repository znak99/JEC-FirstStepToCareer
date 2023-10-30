//
//  MockInterviewManager.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/30.
//

import Foundation

class MockInterviewManager: ObservableObject {
    @Published var isStartInterview = false
    @Published var isShowLoadingIndicator = false
}
