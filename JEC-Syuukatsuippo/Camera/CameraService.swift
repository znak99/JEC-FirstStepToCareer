//
//  CameraService.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import Foundation
import Photos

class CameraService: NSObject {
    let session = AVCaptureSession()
    
    var device: AVCaptureDevice?
    var innerCamera: AVCaptureDevice?
    
    var photoOutput = AVCapturePhotoOutput()
    var videoOutput = AVCaptureMovieFileOutput()
    
    typealias PhotoCaptureCompletion = (Data) -> Void
    var photoCaptureCompletion: PhotoCaptureCompletion?
    
    typealias VideoCaptureCompletion = (URL) -> Void
    var videoCaptureCompletion: VideoCaptureCompletion?
    
    func setupDevice() {
        session.beginConfiguration()
        session.sessionPreset = .photo
         
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                      mediaType: .video,
                                                                      position: .unspecified)
        let devices = deviceDiscoverySession.devices
        for device in devices {
            if device.position == .front {
                innerCamera = device
            }
        }
        
        device = innerCamera
        
        guard session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            return
        }
        
        guard session.canAddOutput(videoOutput) else {
            session.commitConfiguration()
            return
        }
        
        session.addOutput(photoOutput)
        session.addOutput(videoOutput)
        
        if let device = device {
            guard let captureDeviceInput = try? AVCaptureDeviceInput(device: device), session.canAddInput(captureDeviceInput) else {
                session.commitConfiguration()
                return
            }
            
            session.addInput(captureDeviceInput)
        }
        
        session.commitConfiguration()
    }
    
    func start() {
        DispatchQueue(label: "Background", qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func stop() {
        DispatchQueue(label: "Background", qos: .background).async {
            self.session.stopRunning()
        }
    }
    
    func takePhoto(completion: @escaping PhotoCaptureCompletion) {
        self.photoCaptureCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func startRecord(completion: @escaping VideoCaptureCompletion) {
        print("Start video recording")
        self.videoCaptureCompletion = completion
        let url = URL(filePath: NSTemporaryDirectory())
        videoOutput.startRecording(to: url, recordingDelegate: self)
    }
    
    func stopRecord() {
        videoOutput.stopRecording()
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            return
        }

        if let completion = photoCaptureCompletion {
            completion(imageData)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
}

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("비디오 완료")
        if error != nil {
            return
        }
        
        if let completion = videoCaptureCompletion {
            completion(outputFileURL)
        }
    }
}
