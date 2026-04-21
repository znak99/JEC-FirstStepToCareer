//
//  CameraRepresent.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import Foundation
import SwiftUI
import AVFoundation

struct CameraRepresent: UIViewRepresentable {
    typealias UIViewType = CameraPreview
    var cameraService: CameraService
    var previewSize: CGRect
    
    @Binding var isReduceSize: Bool
    
    func makeUIView(context: Context) -> CameraPreview {
        let view = CameraPreview()
        view.cameraService = cameraService
        view.cameraService.setupDevice()
        view.setupLayer(previewSize: previewSize)
        view.cameraService.start()
        return view
    }

    func updateUIView(_ uiView: CameraPreview, context: Context) {
        guard let cameraPreviewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer else { return }
        cameraPreviewLayer.frame = previewSize
        
        if isReduceSize {
            cameraPreviewLayer.cornerRadius = 12
            cameraPreviewLayer.borderWidth = 2
            cameraPreviewLayer.borderColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        }
    }
}
