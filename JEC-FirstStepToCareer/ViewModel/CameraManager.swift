//
//  CameraManager.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/29.
//

import Foundation
import AVFoundation

class CameraManager: ObservableObject {
    let session = AVCaptureSession()
    let output = AVCapturePhotoOutput()
    var preview: AVCaptureVideoPreviewLayer!
    
    // Check camera permission
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                if authorized {
                    DispatchQueue.global(qos: .background).async {
                        self.initializeCamera()
                    }
                } else {
                    // TODO: - unusable camera
                }
            }
        case .restricted:
            return
        case .denied:
            return
        case .authorized:
            DispatchQueue.global(qos: .background).async {
                self.initializeCamera()
            }
            return
        @unknown default:
            return
        }
    }
    
    // Set up camera options
    func initializeCamera() {
        print(123)
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
