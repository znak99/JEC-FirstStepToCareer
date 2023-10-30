//
//  MockInterviewInitializeView.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/31.
//

import SwiftUI

struct MockInterviewInitializeView: View {
    
    let proxy: GeometryProxy
    @ObservedObject var interviewManager: MockInterviewManager
    
    var body: some View {
        VStack {
            HStack {
                Image("FaceDetectionFrameEdge")
                    .resizable()
                    .frame(width: proxy.size.width / 12)
                    .frame(height: proxy.size.width / 12)
                Spacer()
                Image("FaceDetectionFrameEdge")
                    .resizable()
                    .frame(width: proxy.size.width / 12)
                    .frame(height: proxy.size.width / 12)
                    .rotationEffect(.degrees(90))
            }
            HStack {
                Image("FaceDetectionFrameEdge")
                    .resizable()
                    .frame(width: proxy.size.width / 12)
                    .frame(height: proxy.size.width / 12)
                    .rotationEffect(.degrees(270))
                Spacer()
                Image("FaceDetectionFrameEdge")
                    .resizable()
                    .frame(width: proxy.size.width / 12)
                    .frame(height: proxy.size.width / 12)
                    .rotationEffect(.degrees(180))
            }
            .padding(.top, proxy.size.height / 2)
            
            Text("フレームの中に顔の全体を映してください")
                .font(.custom(Font.customBold, size: proxy.size.width / 24))
                .foregroundStyle(.appWhite)
                .padding(.top, proxy.size.height / 120)
            
            
            HStack {
                Spacer()
                Text("顔が認識されると自動で面接が始まります")
                    .font(.custom(Font.customRegular, size: proxy.size.width / 32))
                    .foregroundStyle(.appWhite)
            }
            .padding(.top, proxy.size.height / 120000)
            
            HStack {
                Spacer()
                Text("認識した顔は模擬面接の評価基準として使われます")
                    .font(.custom(Font.customRegular, size: proxy.size.width / 32))
                    .foregroundStyle(.appWhite)
            }
        }
    }
}

#Preview {
    GeometryReader(content: { proxy in
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            MockInterviewInitializeView(proxy: proxy, interviewManager: MockInterviewManager())
        }
    })
}
