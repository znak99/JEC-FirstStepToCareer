//
//  MockInterviewManager.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/30.
//

import SwiftUI

class MockInterviewManager: ObservableObject {
    @Published var isStartInterview = false
    @Published var isShowLoadingIndicator = false
    @Published var recIconOpacity: CGFloat = 1
    @Published var headerText = "模擬面接準備中..."
    
    // Start face detection for mock interview
    func prepareInterview() {
        isStartInterview = true
        headerText = "顔認識中..."
        startRecIconAnimation()
    }
    
    // Clicking animation for rec header icon
    func startRecIconAnimation() {
        withAnimation(.linear(duration: 1).repeatForever()) {
            self.recIconOpacity -= 1
        }
    }
}
