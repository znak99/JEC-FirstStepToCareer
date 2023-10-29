//
//  CameraPreview.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/29.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        CameraService.shared.preview = AVCaptureVideoPreviewLayer(session: CameraService.shared.session)
        CameraService.shared.preview.frame = view.frame
        
        CameraService.shared.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(CameraService.shared.preview)
        
        DispatchQueue.global(qos: .background).async {
            CameraService.shared.session.startRunning()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}
