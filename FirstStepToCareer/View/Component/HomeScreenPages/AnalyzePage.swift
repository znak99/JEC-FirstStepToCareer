//
//  AnalyzePage.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import SwiftUI
import Charts

struct AnalyzePage: View {
    
    let proxy: GeometryProxy
    @ObservedObject var homeManager: HomeManager
    
    @AppStorage("isFirstTimeToLoadAnalyzeData") var analyzeFlag: Bool = true
    
    var body: some View {
        if homeManager.isNoData {
            Text("模擬面接データがありません😟\n模擬面接を行うと分析結果が表示されます")
                .font(.custom(Font.customRegular, size: proxy.size.width / 24))
                .foregroundStyle(.appGray)
                .multilineTextAlignment(.center)
                .padding(.top, proxy.size.height / 10)
        } else {
            VStack(spacing: proxy.size.height / 80) {
                VStack(spacing: 0) {
                    HStack {
                        Text("分析結果")
                            .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                            .foregroundStyle(.appBlack)
                        Spacer()
                    }
                }
                VStack(spacing: proxy.size.height / 16) {
                    VStack {
                        AnalyzeProgressBar(proxy: proxy,
                                           score: homeManager.eyesTotalAvgScore,
                                           title: "目の動き", 
                                           description: "面接での目の動きは信頼性や興味を示し\n相手とのコミュニケーションを強化します\n適切な視線は印象形成に影響します", 
                                           icon: "FeedbackScoreEye")
                        HStack {
                            Text("質問ごとの平均点")
                                .font(.custom(Font.customMedium, size: proxy.size.width / 28))
                                .foregroundStyle(.appBlack)
                            Spacer()
                        }
                        Chart(homeManager.eyesData) { data in
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
                    VStack {
                        AnalyzeProgressBar(proxy: proxy,
                                           score: homeManager.faceTotalAvgScore,
                                           title: "頭の動き",
                                           description: "頭の動きは積極性や理解を示し\n相手との共感を高めます\n適切なヘッドノッドはコミュニケーション効果を向上させます",
                                           icon: "FeedbackScorePerson")
                        HStack {
                            Text("質問ごとの平均点")
                                .font(.custom(Font.customMedium, size: proxy.size.width / 28))
                                .foregroundStyle(.appBlack)
                            Spacer()
                        }
                        Chart(homeManager.faceData) { data in
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
                    VStack {
                        AnalyzeProgressBar(proxy: proxy,
                                           score: homeManager.answerSpeedTotalAvgScore,
                                           title: "回答時間", 
                                           description: "迅速な回答速度は自信と決断力を示し\n印象を強化します\n相手の質問に適切かつ迅速に対応が魅力的です",
                                           icon: "FeedbackScoreClock")
                        HStack {
                            Text("質問ごとの平均点")
                                .font(.custom(Font.customMedium, size: proxy.size.width / 28))
                                .foregroundStyle(.appBlack)
                            Spacer()
                        }
                        Chart(homeManager.answerSpeedData) { data in
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
                    .padding(.bottom)
                }
                .onAppear {
                    if homeManager.isNeedToLoadData {
                        homeManager.clearAnalyzedData()
                        homeManager.isShowLoadingIndicator = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            homeManager.isShowLoadingIndicator = false
                            withAnimation {
                                homeManager.getTotalAvgScores()
                                homeManager.getGraphData()
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    GeometryReader(content: { geometry in
        AnalyzePage(proxy: geometry, homeManager: HomeManager())
    })
}
