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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader(content: { proxy in
            ZStack {
                // Camera preview
                CameraPreview()
                    .ignoresSafeArea()
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
