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
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader(content: { proxy in
            ZStack {
                // Default background
                Color.appBlack
                    .ignoresSafeArea()
                
                // Camera preview
                CameraPreview()
                    .ignoresSafeArea()
                
                // 
                if !interviewManager.isStartInterview {
                    Color.appBlack.opacity(0.3)
                        .ignoresSafeArea()
                }
                
                VStack {
                    MockInterviewHeader(proxy: proxy,
                                        interviewManager: interviewManager) {
                        dismiss()
                    }
                    
                    if interviewManager.isStartInterview {
                        
                    } else {
                        MockInterviewCautionView(proxy: proxy,
                                                 interviewManager: interviewManager)
                        .padding(.top, proxy.size.height / 16)
                    }
                    
                    Spacer()
                }
                .padding()
                
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
    MockInterviewView()
}
