//
//  MockInterviewView.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/28.
//

import SwiftUI
import AVFoundation

struct MockInterviewView: View {
    
    @State var showCameraPermissionDeniedAlert = false
    
    @StateObject var interviewManager = MockInterviewManager()
    @ObservedObject var homeManager: HomeManager
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader(content: { proxy in
            ZStack {
                if interviewManager.initialized {
                    Color.appPrimary
                        .ignoresSafeArea()
                } else {
                    Color.appBlack
                        .ignoresSafeArea()
                }
                
                
                if !interviewManager.initialized {
                    // Camera preview
                    CameraPreview(
                        isForInit: true,
                        x: nil,
                        y: nil,
                        width: nil,
                        height: nil
                    )
                        .ignoresSafeArea()
                }
                
                // Filter
                Color.appBlack.opacity(interviewManager.isStartInterview ? 0.1 : 0.5)
                    .ignoresSafeArea()
                
                VStack {
                    // Header and dismiss button
                    MockInterviewHeader(proxy: proxy,
                                        interviewManager: interviewManager) {
                        interviewManager.cancel()
                        dismiss()
                    }
                    
                    if !interviewManager.initialized {
                        if interviewManager.isStartInterview {
                            MockInterviewInitializeView(proxy: proxy,
                                                        interviewManager: interviewManager)
                            .padding(.top, proxy.size.height / 16)
                        } else {
                            MockInterviewCautionView(proxy: proxy,
                                                     interviewManager: interviewManager)
                            .padding(.top, proxy.size.height / 16)
                        }
                    } else {
                        Text(homeManager.companyName)
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
                    
                    if interviewManager.initialized {
                        VStack {
                            HStack {
                                Text("アクション")
                                    .foregroundStyle(Color.appGray)
                                    .font(.custom(Font.customSemiBold, size: proxy.size.width / 28))
                                Spacer()
                            }
                            .padding()
                            
                            Button(action: {}, label: {
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
                            Button(action: {}, label: {
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
                            Button(action: {}, label: {
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
                
                if interviewManager.initialized {
                   CameraPreview(
                       isForInit: false,
                       x: Int(proxy.size.width / 1.4),
                       y: Int(proxy.size.height / 10),
                       width: Int(proxy.size.width / 4),
                       height: Int(proxy.size.height / 4.5)
                   )
               }
                
                if interviewManager.isShowLoadingIndicator {
                    LoadingIndicator(proxy: proxy)
                }
            }
            .toolbar(.hidden)
            .onAppear {
                self.showCameraPermissionDeniedAlert = !CameraService.shared.checkPermission()
            }
            .onDisappear(perform: {
                CameraService.shared.session.stopRunning()
            })
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
    MockInterviewView(homeManager: HomeManager())
}
