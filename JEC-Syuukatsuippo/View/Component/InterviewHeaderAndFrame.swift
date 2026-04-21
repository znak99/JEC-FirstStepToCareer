//
//  InterviewHeaderAndFrame.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import SwiftUI

struct InterviewHeaderAndFrame: View {
    
    let proxy: GeometryProxy
    
    @ObservedObject var interviewManager: InterviewManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if interviewManager.isStartGenerateReferencePoint {
            VStack {
                HStack(alignment: .bottom) {
                    ZStack {
                        Circle()
                            .fill(.appRed)
                            .frame(width: proxy.size.width / 22)
                            .opacity(interviewManager.recIconOpacity)
                        Circle()
                            .stroke(.appRed, lineWidth: 3)
                            .frame(width: proxy.size.width / 16)
                            .opacity(interviewManager.recIconOpacity)
                    }
                    Text(interviewManager.headerText)
                        .font(.custom(Font.customRegular, size: proxy.size.width / 24))
                        .foregroundStyle(.appWhite)
                    Spacer()
                    if !interviewManager.isReferencePointGenerated {
                        Button(action: {
                            InterviewInfoTemp.shared.clear()
                            dismiss()
                        }, label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: proxy.size.width / 20)
                                .frame(height: proxy.size.width / 20)
                                .foregroundStyle(.appWhite)
                                .padding(proxy.size.width / 48)
                                .background {
                                    RoundedRectangle(cornerRadius: proxy.size.width / 32)
                                        .stroke(.appWhite, lineWidth: 1)
                                }
                        })
                    }
                }
                
                if !interviewManager.isReferencePointGenerated {
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
                            .font(.custom(Font.customBold, size: proxy.size.width / 22))
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
                    .padding(.top, proxy.size.height / 12)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    GeometryReader(content: { proxy in
        InterviewHeaderAndFrame(proxy: proxy, interviewManager: InterviewManager())
    })
}
