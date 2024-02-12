//
//  MockInterviewView.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import SwiftUI

struct MockInterviewView: View {
    
    @StateObject private var interviewManager = MockInterviewManager()
    @StateObject private var sttService = STTService()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if interviewManager.isDetected {
                    Color.appPrimary
                        .ignoresSafeArea()
                } else {
                    Color.appBlack
                        .ignoresSafeArea()
                }
                
                if !interviewManager.isDetected {
                    CameraPreview(
                        isForDetect: true,
                        x: nil,
                        y: nil,
                        width: nil,
                        height: nil
                    )
                        .ignoresSafeArea()
                }
                
                VStack {
                    MockInterviewHeader(proxy: proxy, interviewManager: interviewManager)
                    
                    if interviewManager.isShowFrame && !interviewManager.isDetected {
                        MockInterviewFrame(proxy: proxy, interviewManager: interviewManager)
                            .padding(.top, proxy.size.height / 16)
                    }
                    
                    if interviewManager.isDetected {
                        Text(MockInterviewInfo.shared.companyName)
                            .font(.custom(Font.customBold, size: proxy.size.width / 16))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .background {
                                Capsule()
                                    .foregroundStyle(.white)
                            }
                        
                        Image("AppLogo-White")
                            .resizable()
                            .frame(width: proxy.size.width / 1.3, height: proxy.size.width / 1.3)
                            .padding(.top)
                    }
                    
                    Spacer()
                    
                    if interviewManager.isDetected {
                        if !interviewManager.isAnswerTurn {
                            Text("質問を生成しています...")
                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                .foregroundStyle(.appWhite)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                        } else if interviewManager.isAnswerTurn {
                            Text("回答を録音しています...")
                                .font(.custom(Font.customRegular, size: proxy.size.width / 28))
                                .foregroundStyle(.appWhite)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                        }
                    }
                    
                    if interviewManager.isDetected {
                        VStack {
                            Text(sttService.text)
                            HStack {
                                Text("アクション")
                                    .foregroundStyle(Color.appGray)
                                    .font(.custom(Font.customSemiBold, size: proxy.size.width / 28))
                                Spacer()
                            }
                            .padding()
                            Button(action: {
                                print("abc")
                            }, label: {
                                Text("質問をもう一度読み上げる")
                                    .frame(maxWidth: .infinity)
                                    .padding(6)
                                    .background(.white)
                                    .foregroundStyle(Color.appBlack)
                                    .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                            })
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .appPrimary, radius: 1, x: 0, y: 2)
                            .padding(.horizontal)
                            Button(action: {
                                print("abc")
                            }, label: {
                                Text("質問を再生成する")
                                    .frame(maxWidth: .infinity)
                                    .padding(6)
                                    .background(.white)
                                    .foregroundStyle(Color.appBlack)
                                    .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                            })
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .appPrimary, radius: 1, x: 0, y: 2)
                            .padding(.horizontal)
                            Button(action: {
                                print("abc")
                            }, label: {
                                Text("模擬面接を終了する")
                                    .frame(maxWidth: .infinity)
                                    .padding(6)
                                    .background(.white)
                                    .foregroundStyle(Color.appBlack)
                                    .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                            })
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .appRed, radius: 1, x: 0, y: 2)
                            .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.appWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 4)
                    }
                }
                .padding()
                
                if interviewManager.isShowCautionView {
                    MockInterviewCaution(proxy: proxy, interviewManager: interviewManager)
                }
                
                VStack {
                    if interviewManager.isDetected {
                       CameraPreview(
                           isForDetect: false,
                           x: Int(proxy.size.width / 1.4),
                           y: Int(proxy.size.height / 10),
                           width: Int(proxy.size.width / 4),
                           height: Int(proxy.size.height / 4.5)
                       )
                       .frame(maxHeight: proxy.size.height / 2)
                   }
                    Spacer()
                }
                
                if interviewManager.isShowLoadingIndicator {
                    LoadingIndicator(proxy: proxy)
                }
            }
            .toolbar(.hidden)
            .onAppear {
                interviewManager.isShowCameraPermissionDeniedAlert = !CameraService.shared.checkPermission()
                sttService.requestSpeechAuthorization()
                interviewManager.diSTTService(service: sttService)
            }
            .onDisappear(perform: {
                CameraService.shared.session.stopRunning()
            })
            .onChange(of: sttService.isSTTStopped, perform: { flag in
                if flag {
                    interviewManager.generateQuestion(text: sttService.text)
                }
                
                sttService.isSTTStopped = false
            })
            .onChange(of: sttService.isRecording, perform: { flag in
                if flag {
                    interviewManager.startEstimateLandmarkScore()
                } else {
//                    interviewManager.stopEstimate()
                }
                
            })
            .alert(isPresented: $interviewManager.isShowCameraPermissionDeniedAlert) {
                Alert(title: Text("Camera permission denied"),
                      message: Text("模擬面接はカメラの権限が必要です。\n権限を確認してからもう一度試してください"),
                      dismissButton: .cancel({
                    interviewManager.isShowCameraPermissionDeniedAlert = false
                    dismiss()
                }))
            }
        }
    }
}

#Preview {
    MockInterviewView()
}
