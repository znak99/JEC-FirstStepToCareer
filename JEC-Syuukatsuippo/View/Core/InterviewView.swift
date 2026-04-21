//
//  InterviewView.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import SwiftUI

struct InterviewView: View {
    
    @ObservedObject var interviewManager: InterviewManager
    @StateObject private var sttService = STTService()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if interviewManager.isReferencePointGenerated {
                    Color.appPrimary.ignoresSafeArea()
                } else {
                    Color.appBlack.ignoresSafeArea()
                }
                
                InterviewBackground(proxy: proxy, interviewManager: interviewManager)
                
                CameraRepresent(cameraService: interviewManager.cameraService,
                                previewSize: interviewManager.previewSize, 
                                isReduceSize: $interviewManager.isReferencePointGenerated)
                .ignoresSafeArea()
                .onDisappear {
                    interviewManager.cameraService.stop()
                }
                
                InterviewHeaderAndFrame(proxy: proxy, interviewManager: interviewManager)
                
                if !interviewManager.isStartGenerateReferencePoint {
                    InterviewCaution(proxy: proxy, interviewManager: interviewManager)
                }
                
                if interviewManager.isReferencePointGenerated {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: proxy.size.height / 48) {
                            HStack {
                                Spacer()
                                Text(interviewManager.statusMessage)
                                    .foregroundStyle(Color.appBlack)
                                    .font(.custom(Font.customMedium, size: proxy.size.width / 22))
                                Spacer()
                            }
                            HStack {
                                Text("アクション")
                                    .foregroundStyle(Color.appGray)
                                    .font(.custom(Font.customSemiBold, size: proxy.size.width / 28))
                                Spacer()
                            }
                            .padding()
                            Button(action: {
                                if !interviewManager.isGeneratingQuestion || !interviewManager.isSpeaking {
                                    interviewManager.isReplayQuestion = true
                                }
                            }, label: {
                                Text("質問をもう一度読み上げる")
                                    .frame(maxWidth: .infinity)
                                    .padding(6)
                                    .background(.white)
                                    .foregroundStyle(Color.appBlack)
                                    .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .appPrimary, radius: 1, x: 0, y: 2)
                                    .padding(.horizontal)
                            })
                            
                            Button(action: {
                                if !interviewManager.synthesizer.isSpeaking {
                                    interviewManager.isRegenerateQuestion = true
                                }
                            }, label: {
                                Text("質問を再生成する")
                                    .frame(maxWidth: .infinity)
                                    .padding(6)
                                    .background(.white)
                                    .foregroundStyle(Color.appBlack)
                                    .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .appPrimary, radius: 1, x: 0, y: 2)
                                    .padding(.horizontal)
                            })
                            
                            Button(action: {
                                if !interviewManager.synthesizer.isSpeaking {
                                    interviewManager.isShowQuitAlert.toggle()
                                }
                            }, label: {
                                Text("模擬面接を終了する")
                                    .frame(maxWidth: .infinity)
                                    .padding(6)
                                    .background(.white)
                                    .foregroundStyle(Color.appBlack)
                                    .font(.custom(Font.customMedium, size: proxy.size.width / 24))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .appRed, radius: 1, x: 0, y: 2)
                                    .padding()
                            })
                            .alert("面接終了", isPresented: $interviewManager.isShowQuitAlert) {
                                Button("終了する", role: .destructive) {
                                    interviewManager.dismissAction()
                                    sttService.stopRecord()
                                    dismiss()
                                }
                                Button("戻る", role: .cancel) {}
                            } message: {
                                Text("この面接のデータは保存されません")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.appWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 4)
                        .padding()
                    }
                }
                
                if interviewManager.isShowLoadingIndicator {
                    LoadingIndicator(proxy: proxy)
                }
            }
            .navigationDestination(isPresented: $interviewManager.isNavigateToInterviewResultView) {
                InterviewResultView(interviewManager: interviewManager)
            }
            .toolbar(.hidden)
            .onChange(of: interviewManager.isReferencePointGenerated, perform: { _ in
                interviewManager.reducePreviewSize()
                DispatchQueue.global().async {
                    interviewManager.cameraService.startRecord { url in
                        DispatchQueue.main.async {
                            interviewManager.videoUrl = url
                        }
                        
                    }
                }
            })
            .onChange(of: interviewManager.isRecording, perform: { isRecording in
                if isRecording && interviewManager.questionCount < 8 {
                    sttService.startRecord()
                }
            })
            .onChange(of: interviewManager.isReplayQuestion, perform: { isReplay in
                if isReplay {
                    if sttService.isRecording {
                        sttService.stopRecord()
                    }
                    
                    interviewManager.replayQuestion()
                }
            })
            .onChange(of: interviewManager.isRegenerateQuestion, perform: { isRegenerate in
                if isRegenerate {
                    if sttService.isRecording {
                        sttService.stopRecord()
                    }
                    
                    interviewManager.regenerateConversation()
                }
            })
            .onChange(of: sttService.isRecording, perform: { isRecording in
                print("DEBUG - isReplayQuestion: \(interviewManager.isReplayQuestion)")
                if !interviewManager.isReplayQuestion && !interviewManager.isWillDismiss && !interviewManager.isRegenerateQuestion {
                    if !isRecording && interviewManager.questionCount < 7 {
                        interviewManager.isDetectingFaceRect = false
                        interviewManager.continueConversation(message: sttService.text)
                    } else if !isRecording && interviewManager.questionCount >= 7 {
                        interviewManager.isDetectingFaceRect = false
                        interviewManager.finishConversation(message: sttService.text)
                    } else if isRecording && interviewManager.questionCount < 7 {
                        interviewManager.isDetectingFaceRect = false
                        interviewManager.generateFaceRect()
                    }
                }
            })
        }
    }
}

#Preview {
    InterviewView(interviewManager: InterviewManager())
}
