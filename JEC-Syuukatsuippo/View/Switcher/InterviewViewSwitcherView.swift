//
//  InterviewViewSwitcherView.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/14.
//

import SwiftUI

struct InterviewViewSwitcherView: View {
    
    @StateObject private var interviewManager = InterviewManager()
    @ObservedObject var homeManager: HomeManager
    
    var body: some View {
        if interviewManager.isNavigateToInterviewResultView {
            InterviewResultView(interviewManager: interviewManager)
        } else {
            InterviewView(interviewManager: interviewManager)
                .onAppear {
                    homeManager.isLoadGraphData = true
                }
        }
    }
}

#Preview {
    InterviewViewSwitcherView(homeManager: HomeManager())
}
