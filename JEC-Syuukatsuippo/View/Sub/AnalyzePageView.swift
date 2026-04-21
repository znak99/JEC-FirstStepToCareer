//
//  AnalyzePageView.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import SwiftUI
import Charts

struct AnalyzePageView: View {
    
    let proxy: GeometryProxy
    
    @ObservedObject var homeManager: HomeManager
    
    @State private var categories = [
        (title: "目の動き",
         description: "面接での目の動きは信頼性や興味を示し\n相手とのコミュニケーションを強化します\n適切な視線は印象形成に影響します",
         icon: "FeedbackScoreEye"),
        (title: "頭の動き",
         description: "頭の動きは積極性や理解を示し\n相手との共感を高めます\n適切なヘッドノッドは会話の質を向上させます",
         icon: "FeedbackScorePerson"),
        (title: "回答時間",
         description: "迅速な回答速度は自信と決断力を示し\n印象を強化します\n相手の質問に適切かつ迅速な対応が魅力的です",
         icon: "FeedbackScoreClock"),
    ]
    
    var body: some View {
        VStack(spacing: proxy.size.height / 80) {
            if homeManager.isInterviewDataEmpty {
                HStack {
                    Spacer()
                    Image(systemName: "square.stack.3d.up.slash")
                        .resizable()
                        .frame(width: proxy.size.width / 3)
                        .frame(height: proxy.size.width / 3)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.top)
                Group {
                    Text("模擬面接データがありません")
                    Text("模擬面接を行うと分析結果が表示されます")
                }
                .font(.custom(Font.customRegular, size: proxy.size.width / 24))
                .multilineTextAlignment(.center)
            } else {
                HStack {
                    Text("分析結果")
                        .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                        .foregroundStyle(.appBlack)
                    Spacer()
                }
                VStack(spacing: proxy.size.height / 16) {
                    ForEach(0..<3) { index in
                        VStack {
                            VStack(spacing: 0) {
                                HStack {
                                    Image(categories[index].icon)
                                        .resizable()
                                        .frame(width: proxy.size.width / 16)
                                        .frame(height: proxy.size.width / 16)
                                    Text(categories[index].title)
                                        .font(.custom(Font.customMedium, size: proxy.size.width / 20))
                                        .foregroundStyle(.appBlack)
                                }
                                
                                HStack {
                                    Text(categories[index].description)
                                        .font(.custom(Font.customMedium, size: proxy.size.width / 28))
                                        .foregroundStyle(.appGray)
                                        .multilineTextAlignment(.center)
                                }
                                HStack {
                                    Text("総合平均点")
                                        .font(.custom(Font.customMedium, size: proxy.size.width / 28))
                                        .foregroundStyle(.appBlack)
                                    Spacer()
                                }
                                .padding(.top)
                                ZStack(alignment: .leading) {
                                    if categories[index].title == "目の動き" {
                                        if homeManager.eyesTotalAvgScore == 100 {
                                            Capsule()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: proxy.size.width / 24)
                                                .foregroundStyle(.appPrimary)
                                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                        } else {
                                            Capsule()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: proxy.size.width / 24)
                                                .foregroundStyle(.white)
                                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                            Capsule()
                                                .frame(width: CGFloat(homeManager.eyesTotalAvgScore) *
                                                       ((proxy.size.width - proxy.size.width / 13) / 100))
                                                .frame(height: proxy.size.width / 24)
                                                .foregroundStyle(.appPrimary)
                                        }
                                    } else if categories[index].title == "頭の動き" {
                                        if homeManager.faceTotalAvgScore == 100 {
                                            Capsule()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: proxy.size.width / 24)
                                                .foregroundStyle(.appPrimary)
                                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                        } else {
                                            Capsule()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: proxy.size.width / 24)
                                                .foregroundStyle(.white)
                                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                            Capsule()
                                                .frame(width: CGFloat(homeManager.faceTotalAvgScore) *
                                                       ((proxy.size.width - proxy.size.width / 13) / 100))
                                                .frame(height: proxy.size.width / 24)
                                                .foregroundStyle(.appPrimary)
                                        }
                                    } else if categories[index].title == "回答時間" {
                                        if homeManager.answerSpeedTotalAvgScore == 100 {
                                            Capsule()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: proxy.size.width / 24)
                                                .foregroundStyle(.appPrimary)
                                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                        } else {
                                            Capsule()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: proxy.size.width / 24)
                                                .foregroundStyle(.white)
                                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                            Capsule()
                                                .frame(width: CGFloat(homeManager.answerSpeedTotalAvgScore) *
                                                       ((proxy.size.width - proxy.size.width / 13) / 100))
                                                .frame(height: proxy.size.width / 24)
                                                .foregroundStyle(.appPrimary)
                                        }
                                    }
                                }
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading) {
                                        Text("|")
                                            .font(.custom(Font.customRegular, size: proxy.size.width / 100))
                                        Text("0")
                                    }
                                    Spacer()
                                    VStack(alignment: .center) {
                                        Text("|")
                                            .font(.custom(Font.customRegular, size: proxy.size.width / 100))
                                        Text("50")
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("|")
                                            .font(.custom(Font.customRegular, size: proxy.size.width / 100))
                                        Text("100")
                                    }
                                }
                                .font(.custom(Font.customRegular, size: proxy.size.width / 60))
                                .foregroundStyle(.appGray)
                            }
                            HStack {
                                Text("質問ごとの平均点")
                                    .font(.custom(Font.customMedium, size: proxy.size.width / 28))
                                    .foregroundStyle(.appBlack)
                                Spacer()
                            }
                            Chart(categories[index].title == "目の動き"
                                  ? homeManager.eyesGraphData : categories[index].title == "頭の動き"
                                  ? homeManager.faceGraphData : homeManager.answerSpeedGraphData) { data in
                                LineMark(
                                    x: .value("質問", data.count),
                                    y: .value("点数", data.score))
                                PointMark(
                                    x: .value("質問", data.count),
                                    y: .value("点数", data.score))
                            }
                            .chartYScale(domain: 0...100)
                            .foregroundStyle(.appPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: proxy.size.height / 8)
                            .padding(.bottom)
                        }
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: proxy.size.width / 24))
                        .shadow(radius: 2)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            if homeManager.isLoadGraphData {
                homeManager.checkInterviewDataEmpty()
                if !homeManager.isInterviewDataEmpty {
                    homeManager.clearGraphData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            homeManager.calcAnalyzeData()
                        }
                    }
                }
            }
            homeManager.isLoadGraphData = false
        }
    }
}

#Preview {
    GeometryReader(content: { proxy in
        AnalyzePageView(proxy: proxy, homeManager: HomeManager())
    })
}
