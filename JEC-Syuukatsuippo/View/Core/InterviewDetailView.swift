//
//  InterviewDetailView.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import SwiftUI

struct InterviewDetailView: View {
    
    let interview: MockInterview
    
    @ObservedObject var homeManager: HomeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var togglers: [Bool] = [
        false, false, false, false, false, false, false
    ]
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.appWhite.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
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
                                Text(InterviewInfoTemp.shared.formatDateWithDay(date: interview.date))
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
                        
                        ForEach(0..<7) { index in
                            Button(action: {
                                withAnimation {
                                    togglers[index].toggle()
                                }
                            }, label: {
                                VStack {
                                    HStack() {
                                        RoundedRectangle(cornerRadius: 2)
                                            .frame(width: proxy.size.width / 24)
                                            .frame(height: proxy.size.width / 12)
                                            .foregroundStyle(.appPrimary)
                                        Text("\(index + 1)回目の質問")
                                            .font(.custom(Font.customSemiBold, size: proxy.size.width / 24))
                                            .foregroundStyle(.appBlack)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .resizable()
                                            .frame(width: proxy.size.width / 24)
                                            .frame(height: proxy.size.width / 40)
                                            .foregroundStyle(.appGray)
                                            .rotationEffect(.degrees(togglers[index] ? 180 : 0))
                                    }
                                    if togglers[index] {
                                        Group {
                                            Text("Question")
                                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                                .foregroundStyle(.appGray)
                                            Text(interview.questions[index])
                                                .padding()
                                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                                .foregroundStyle(.appBlack)
                                                .frame(maxWidth: .infinity)
                                                .background(.appWhite)
                                                .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 48))
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: proxy.size.width / 48)
                                                        .stroke(.appPrimary, lineWidth: 1)
                                                }
                                        }
                                        Group {
                                            Text("Answer")
                                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                                .foregroundStyle(.appGray)
                                            Text(interview.answers[index])
                                                .padding()
                                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                                .foregroundStyle(.appBlack)
                                                .frame(maxWidth: .infinity)
                                                .background(.appWhite)
                                                .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 48))
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: proxy.size.width / 48)
                                                        .stroke(.appPrimary, lineWidth: 1)
                                                }
                                        }
                                        Text("Score")
                                            .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                            .foregroundStyle(.appGray)
                                        HStack(alignment: .center) {
                                            Image("FeedbackScoreEye")
                                                .resizable()
                                                .frame(width: proxy.size.width / 24)
                                                .frame(height: proxy.size.width / 24)
                                            Text("目の動き")
                                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                                .foregroundStyle(.appBlack)
                                            Spacer()
                                            Text("\(interview.eyesScores[index])点")
                                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                                .foregroundStyle(.appBlack)
                                        }
                                        HStack(alignment: .center) {
                                            Image("FeedbackScorePerson")
                                                .resizable()
                                                .frame(width: proxy.size.width / 24)
                                                .frame(height: proxy.size.width / 24)
                                            Text("頭の動き")
                                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                                .foregroundStyle(.appBlack)
                                            Spacer()
                                            Text("\(interview.faceScores[index])点")
                                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                                .foregroundStyle(.appBlack)
                                        }
                                        HStack(alignment: .center) {
                                            Image("FeedbackScoreClock")
                                                .resizable()
                                                .frame(width: proxy.size.width / 24)
                                                .frame(height: proxy.size.width / 24)
                                            Text("回答速度")
                                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                                .foregroundStyle(.appBlack)
                                            Spacer()
                                            Text("\(interview.answerSpeedScores[index])点")
                                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                                .foregroundStyle(.appBlack)
                                        }
                                    }
                                }
                                .padding(proxy.size.width / 32)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 48))
                                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                            })
                            .padding(.horizontal, proxy.size.width / 100)
                            .padding(.top)
                            .buttonStyle(PlainButtonStyle())
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
    InterviewDetailView(interview: MockInterview(), homeManager: HomeManager())
}
