//
//  InterviewFeedbackHeader.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/28.
//

import SwiftUI

struct InterviewFeedbackHeader: View {
    
    let proxy: GeometryProxy
    let interview: MockInterview
    @ObservedObject var homeManager: HomeManager
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack(alignment: .bottom) {
                Text("過去の模擬面接")
                    .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                    .foregroundStyle(.appGray)
                Spacer()
                Button(action: { dismiss() }, label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: proxy.size.width / 20)
                        .frame(height: proxy.size.width / 20)
                        .foregroundStyle(.appGray)
                })
                .padding(proxy.size.width / 48)
                .background {
                    RoundedRectangle(cornerRadius: proxy.size.width / 32)
                        .stroke(.appGray, lineWidth: 1)
                }
                .padding([.top, .trailing], 2)
            }
            
            HStack(alignment: .bottom) {
                Text(interview.companyName)
                    .font(.custom(Font.customSemiBold,
                                  size: proxy.size.width / 20))
                    .foregroundStyle(.appBlack)
                    .lineLimit(1)
                    
                Spacer()
                Text(homeManager.formatDateWithDay(date: interview.date))
                    .font(.custom(Font.customRegular,
                                  size: proxy.size.width / 28))
                    .foregroundStyle(.appGray)
            }
            
            HStack {
                Spacer()
                HStack(alignment: .bottom) {
                    Text("この模擬面接の総合評価")
                        .font(.custom(Font.customSemiBold,
                                      size: proxy.size.width / 28))
                        .foregroundStyle(.appGray)
                    Text("\(interview.totalScore)点")
                        .font(.custom(Font.customSemiBold,
                                      size: proxy.size.width / 16))
                        .foregroundStyle(.appBlack)
                }
                .overlay {
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: proxy.size.width / 24)
                            .frame(height: proxy.size.width / 100)
                            .foregroundStyle(Color.appPrimary)
                            .offset(y: 4)
                    }
                }
            }
            
            HStack(alignment: .top) {
                Image("InterviewFeedback")
                    .resizable()
                    .frame(width: proxy.size.width / 16)
                    .frame(height: proxy.size.width / 16)
                    .foregroundStyle(.appBlack)
                VStack(alignment: .leading) {
                    Text("面接内容のフィードバック")
                        .font(.custom(Font.customSemiBold,
                                      size: proxy.size.width / 24))
                        .foregroundStyle(.appBlack)
                    Text(interview.interviewFeedback == "" ? "なし" : interview.interviewFeedback)
                        .font(.custom(Font.customRegular,
                                      size: proxy.size.width / 28))
                        
                        .foregroundStyle(.appGray)
                }
                Spacer()
            }
            .padding(.top, proxy.size.height / 120)
        }
    }
}

#Preview {
    GeometryReader { proxy in
        InterviewFeedbackHeader(proxy: proxy, interview: MockInterview(), homeManager: HomeManager())
    }
}
