//
//  MockInterviewInitializeView.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/28.
//

import SwiftUI
import AVFoundation

struct MockInterviewInitializeView: View {
    
    @State var showCameraPermissionDeniedAlert = false
    
    @StateObject var interviewManager = MockInterviewManager()
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader(content: { proxy in
            ZStack {
                // Camera preview
                CameraPreview()
                    .ignoresSafeArea()
                
                Color.appBlack
                    .opacity(interviewManager.isStartInterview ? 0 : 0.3)
                    .ignoresSafeArea()
                
                // UI
                VStack {
                    // Notice and dismiss button
                    HStack(alignment: .bottom) {
                        ZStack {
                            Circle()
                                .fill(.appRed)
                                .frame(width: proxy.size.width / 22)
                            Circle()
                                .stroke(.appRed, lineWidth: 3)
                                .frame(width: proxy.size.width / 16)
                        }
                        Text("模擬面接準備中...")
                            .font(.custom(Font.customRegular, size: proxy.size.width / 24))
                            .foregroundStyle(.appWhite)
                        Spacer()
                        Button(action: { dismiss() }, label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: proxy.size.width / 20)
                                .frame(height: proxy.size.width / 20)
                                .foregroundStyle(.appWhite)
                        })
                        .padding(proxy.size.width / 48)
                        .background {
                            RoundedRectangle(cornerRadius: proxy.size.width / 32)
                                .stroke(.appWhite, lineWidth: 1)
                        }
                    }
                    
                    // Face detection frame
                    if !interviewManager.isStartInterview {
                        HStack {
                            Image("FaceDetectionFrameEdge")
                                .resizable()
                                .frame(width: proxy.size.width / 16)
                                .frame(height: proxy.size.width / 16)
                            Spacer()
                            Image("FaceDetectionFrameEdge")
                                .resizable()
                                .frame(width: proxy.size.width / 16)
                                .frame(height: proxy.size.width / 16)
                                .rotationEffect(.degrees(90))
                        }
                        .padding(.top, proxy.size.height / 8)
                        
                        HStack {
                            Image("FaceDetectionFrameEdge")
                                .resizable()
                                .frame(width: proxy.size.width / 16)
                                .frame(height: proxy.size.width / 16)
                                .rotationEffect(.degrees(270))
                            Spacer()
                            Image("FaceDetectionFrameEdge")
                                .resizable()
                                .frame(width: proxy.size.width / 16)
                                .frame(height: proxy.size.width / 16)
                                .rotationEffect(.degrees(180))
                        }
                        .padding(.top, proxy.size.height / 2)
                    }
                    
                    Spacer()
                    
                    // TODO: -  버튼누르면 얼굴인식 시작
//                    Button(action: {}, label: {
//                        /*@START_MENU_TOKEN@*/Text("Button")/*@END_MENU_TOKEN@*/
//                    })
                }
                .padding()
            }
            .toolbar(.hidden)
            .onAppear {
                self.showCameraPermissionDeniedAlert = !CameraService.shared.checkPermission()
            }
            .alert(isPresented: $showCameraPermissionDeniedAlert) {
                Alert(title: Text("Camera permission denied"),
                      message: Text("模擬面接はカメラの権限が必要です。\n権限を確認してからもう一度試してください"),
                      dismissButton: .cancel({
                    showCameraPermissionDeniedAlert = false
                    dismiss()
                }))
            }
        })
    }
}

#Preview {
    MockInterviewInitializeView()
}
