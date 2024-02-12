//
//  HistoryDetailView.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/28.
//

import SwiftUI

struct HistoryDetailView: View {
    
    let interview: MockInterview
    @ObservedObject var homeManager: HomeManager
    
    @State var togglers: [Bool] = [
        false, false, false, false,
        false, false, false
    ]
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.appWhite.ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        InterviewFeedbackHeader(proxy: proxy, 
                                                interview: interview,
                                                homeManager: homeManager)
                        ForEach(0..<7) { index in
                            InterviewFeedbackQuestion(proxy: proxy,
                                                      interview: interview,
                                                      index: index,
                                                      toggler: $togglers[index]
                            )
                        }
                        Spacer()
                    }
                }
                .padding([.top, .horizontal])
            }
            .toolbar(.hidden)
        }
    }
}

#Preview {
    HistoryDetailView(interview: MockInterview(), homeManager: HomeManager())
}
