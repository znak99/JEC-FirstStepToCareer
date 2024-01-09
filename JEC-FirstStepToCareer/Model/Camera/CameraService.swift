//
//  CameraService.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/30.
//

import SwiftUI
import Foundation
import AVFoundation

class CameraService: NSObject, AVCapturePhotoCaptureDelegate {
    
    static let shared = CameraService()
    
    let session = AVCaptureSession()
    let output = AVCapturePhotoOutput()
    var preview: AVCaptureVideoPreviewLayer!
    var capturedData = Data(count: 0)
    
    private override init() {}
    
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
    
    func captureFrame() {
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        self.capturedData = imageData
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
    
    func frameToPNGData() -> Data? {
        return UIImage(data: self.capturedData)?.pngData()
    }
}
