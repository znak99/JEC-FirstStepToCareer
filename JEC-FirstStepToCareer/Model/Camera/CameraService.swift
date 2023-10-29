//
//  CameraService.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/30.
//

import Foundation
import AVFoundation

class CameraService {
    
    static let shared = CameraService()
    
    let session = AVCaptureSession()
    let output = AVCapturePhotoOutput()
    var preview: AVCaptureVideoPreviewLayer!
    
    private init() {}
    
    func checkPermission() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            var flag = true
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                if authorized {
                    DispatchQueue.global(qos: .background).async {
                        self.initializeCamera()
                    }
                }
                flag = authorized
            }
            return flag
        case .restricted:
            return false
        case .denied:
            return false
        case .authorized:
            DispatchQueue.global(qos: .background).async {
                self.initializeCamera()
            }
            return true
        @unknown default:
            return false
        }
    }
    
    func initializeCamera() {
        do {
            self.session.beginConfiguration()
            
            let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .front)
            let input = try AVCaptureDeviceInput(device: device!)
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
        } catch {
            print(error.localizedDescription)
        }
    }
}
