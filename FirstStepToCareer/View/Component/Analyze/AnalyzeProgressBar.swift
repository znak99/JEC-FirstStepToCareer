//
//  AnalyzeProgressBar.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/02/02.
//

import Foundation
import SwiftUI

struct AnalyzeProgressBar: View {
    
    let proxy: GeometryProxy
    let score: Int
    
    @State var title: String
    @State var description: String
    @State var icon: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(icon)
                    .resizable()
                    .frame(width: proxy.size.width / 16)
                    .frame(height: proxy.size.width / 16)
                Text(title)
                    .font(.custom(Font.customMedium, size: proxy.size.width / 20))
                    .foregroundStyle(.appBlack)
            }
            
            HStack {
                Text(description)
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
                if score == 100 {
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
                        .frame(width: CGFloat(score) * ((proxy.size.width - proxy.size.width / 13) / 100))
                        .frame(height: proxy.size.width / 24)
                        .foregroundStyle(.appPrimary)
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
    }
}

#Preview {
    GeometryReader { proxy in
        AnalyzeProgressBar(proxy: proxy, score: 34, title: "asdf", description: "面接での目の動きは信頼性や興味を示し、相手とのコミュニケーションを強化します。適切な視線は印象形成に影響します。", icon: "FeedbackScoreClock")
    }
}
