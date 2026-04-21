//
//  HistoryPageView.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import SwiftUI

struct HistoryPageView: View {
    
    let proxy: GeometryProxy
    
    @ObservedObject var homeManager: HomeManager
    
    var body: some View {
        VStack(spacing: proxy.size.height / 60) {
            VStack(spacing: proxy.size.height / 80) {
                HStack(alignment: .bottom) {
                    Text("過去の模擬面接")
                        .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                        .foregroundStyle(.appBlack)
                    Spacer()
                    Text("(\(homeManager.mockInterviews.count))")
                        .font(.custom(Font.customRegular, size: proxy.size.width / 32))
                        .foregroundStyle(.appGray)
                }
                .padding(.bottom, proxy.size.height / 48)
                
                ForEach(homeManager.mockInterviews, id: \.self) { interview in
                    NavigationLink(destination: InterviewDetailView(interview: interview, homeManager: homeManager)) {
                        VStack(spacing: 0) {
                            HStack(alignment: .top) {
                                Group {
                                    Image(systemName: interview.interviewTypeIcon)
                                        .resizable()
                                        .frame(width: proxy.size.width / 28)
                                        .frame(height: proxy.size.width / 28)
                                        .foregroundStyle(Color.appPrimary)
                                    Text(InterviewInfoTemp.shared.formatDate(date: interview.date))
                                        .font(.custom(Font.customRegular, size: proxy.size.width / 32))
                                        .foregroundStyle(.appGray)
                                }
                                Spacer()
                            }
                            
                            HStack {
                                Text(interview.companyName)
                                    .font(.custom(Font.customSemiBold, size: proxy.size.width / 24))
                                    .foregroundStyle(.appBlack)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.trailing)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .resizable()
                                    .frame(width: proxy.size.width / 48)
                                    .frame(height: proxy.size.width / 32)
                                    .foregroundStyle(.appPrimary)
                            }
                        }
                        .padding(proxy.size.width / 36)
                        .background {
                            RoundedRectangle(cornerRadius: proxy.size.width / 48)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.1), radius: 6)
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            homeManager.getInterviews()
        }
    }
}

#Preview {
    GeometryReader(content: { proxy in
        HistoryPageView(proxy: proxy, homeManager: HomeManager())
    })
}
