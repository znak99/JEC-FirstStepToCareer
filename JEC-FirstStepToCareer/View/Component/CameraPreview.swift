//
//  CameraPreview.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/29.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    
    let isForInit: Bool
    
    let x: Int?
    let y: Int?
    let width: Int?
    let height: Int?
    
    func makeUIView(context: Context) -> UIView {
        CameraService.shared.preview = AVCaptureVideoPreviewLayer(session: CameraService.shared.session)
        if isForInit {
            let view = UIView(frame: UIScreen.main.bounds)
            CameraService.shared.preview.frame = view.frame
            CameraService.shared.preview.videoGravity = .resizeAspectFill
            view.layer.addSublayer(CameraService.shared.preview)
            DispatchQueue.global(qos: .background).async {
                CameraService.shared.session.startRunning()
            }
            return view
        } else {
            var frame = CGRect(x: 30, y: 100, width: 150, height: 280)
            
            if let x, let y, let width, let height {
                frame = CGRect(x: x, y: y, width: width, height: height)
            }
            
            let view = UIView(frame: frame)
            CameraService.shared.preview.frame = view.frame
            CameraService.shared.preview.videoGravity = .resize
            CameraService.shared.preview.borderColor = CGColor(red: 114, green: 198, blue: 255, alpha: 1)
            CameraService.shared.preview.cornerRadius = 12
            CameraService.shared.preview.borderWidth = 2
            
            view.layer.addSublayer(CameraService.shared.preview)
            DispatchQueue.global(qos: .background).async {
                CameraService.shared.session.startRunning()
            }
            return view
        }
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}
