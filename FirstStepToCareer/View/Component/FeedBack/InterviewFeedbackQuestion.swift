//
//  InterviewFeedbackQuestion.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/28.
//

import SwiftUI

struct InterviewFeedbackQuestion: View {
    
    let proxy: GeometryProxy
    let interview: MockInterview
    let index: Int
    
    @Binding var toggler: Bool
    
    var body: some View {
        Button(action: {
            if !toggler {
                withAnimation {
                    toggler.toggle()
                }
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
                    Button(action: {
                        withAnimation {
                            toggler.toggle()
                        }
                    }, label: {
                        Image(systemName: "chevron.down")
                            .resizable()
                            .frame(width: proxy.size.width / 24)
                            .frame(height: proxy.size.width / 40)
                            .foregroundStyle(.appGray)
                            .rotationEffect(.degrees(toggler ? 180 : 0))
                    })
                    .buttonStyle(PlainButtonStyle())
                }
                if toggler {
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
        })
        .padding(proxy.size.width / 32)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 48))
        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        .padding(.horizontal, proxy.size.width / 100)
        .padding(.top)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GeometryReader { proxy in
        InterviewFeedbackQuestion(proxy: proxy, interview: MockInterview(), index: 0, toggler: .constant(false))
    }
}
