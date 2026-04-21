//
//  CameraPreview.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import SwiftUI
import Photos

class CameraPreview: UIView {
    var cameraService = CameraService()
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    func setupLayer(previewSize: CGRect) {
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: cameraService.session)
        cameraPreviewLayer?.videoGravity = .resizeAspectFill
        
        cameraPreviewLayer?.connection?.videoOrientation = .portrait
        
        cameraPreviewLayer?.frame = previewSize
        
        if let cameraPreviewLayer = cameraPreviewLayer {
            self.layer.addSublayer(cameraPreviewLayer)
        }
    }
}
