//
//  MockInterviewManager.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/30.
//

import SwiftUI
import Combine

class MockInterviewManager: ObservableObject {
    @Published var isStartInterview = false
    @Published var isShowLoadingIndicator = false
    @Published var recIconOpacity: CGFloat = 1
    @Published var headerText = "模擬面接準備中..."
    @Published var initialized = false
    
    private var timer: AnyCancellable?
    private var detectedCoordinate: [[Double]] = []
    private var detectedAverage: [Double] = []
    
    // Start face detection for mock interview
    func prepareInterview() {
        isStartInterview = true
        headerText = "顔認識中..."
        startRecIconAnimation()
        print("ABC")
        detectFaceForInitialize()
    }
    
    // Send frame to server to detect face
    func detectFaceForInitialize() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if detectedCoordinate.count < 5 {
                    CameraService.shared.captureFrame()
                    let encodedData = CameraService.shared.frameToPNGData()?.base64EncodedString()
                    
                    let params = ["encoded_frame_data": encodedData]
                    guard let postData = try? JSONSerialization.data(withJSONObject: params) else {
                        print("Failed to serialize data")
                        return
                    }
                    
                    var request = URLRequest(url: AppConstants.requestUrl(path: "detect/face")!)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = postData
                    
                    let task = URLSession.shared.dataTask(with: request) { data, response, error in
                        if let error = error {
                            print("Error: \(error)")
                            return
                        }

                        guard let httpResponse = response as? HTTPURLResponse,
                              (200...299).contains(httpResponse.statusCode) else {
                            print("Invalid response")
                            return
                        }
                        
                        guard let data = data else {
                            return
                        }
                        
                        do {
                            let res = try JSONDecoder().decode(DetectFaceResponse.self, from: data)
                            if res.result {
                                if let left = res.detections?.left,
                                   let top = res.detections?.top,
                                   let right = res.detections?.right,
                                   let bottom = res.detections?.bottom {
                                    self.detectedCoordinate.append([left, top, right, bottom])
                                    print(self.detectedCoordinate)
                                }
                            }
                        } catch (let err) {
                            print(err.localizedDescription)
                        }
                    }
                    
                    task.resume()
                } else {
                    var leftCoordinate: Double = 0
                    var topCoordinate: Double = 0
                    var rightCoordinate: Double = 0
                    var bottomCoordinate: Double = 0
                    
                    for coordinate in self.detectedCoordinate {
                        leftCoordinate += coordinate[0]
                        topCoordinate += coordinate[1]
                        rightCoordinate += coordinate[2]
                        bottomCoordinate += coordinate[3]
                    }
                    
                    self.detectedAverage = [
                        leftCoordinate / Double(self.detectedCoordinate.count),
                        topCoordinate / Double(self.detectedCoordinate.count),
                        rightCoordinate / Double(self.detectedCoordinate.count),
                        bottomCoordinate / Double(self.detectedCoordinate.count),
                    ]
                    self.detectedCoordinate = []
                    timer?.cancel()
                    timer = nil
                    self.initialized = true
                }
            }
    }
    
    
    
    // Clicking animation for rec header icon
    func startRecIconAnimation() {
        withAnimation(.linear(duration: 1).repeatForever()) {
            self.recIconOpacity -= 1
        }
    }
}
