//
//  MockInterviewManager.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import SwiftUI
import Combine
import AVFAudio

class MockInterviewManager: ObservableObject {
    // Toggler
    @Published var isDetected = false
    @Published var isShowCameraPermissionDeniedAlert = false
    @Published var isShowCautionView = true
    @Published var isShowFrame = false
    @Published var isAnswerTurn = false
    @Published var isShowLoadingIndicator = false
    
    @Published var recIconOpacity: CGFloat = 1
    @Published var headerText = "模擬面接準備中..."
    
    @Published var navigateToResult = false
    
    @Published var isDetectionStart = false
    
    // STT
    @Published var isRecording = false
    static var sttService: STTService?
    
    private var questionCount = 0
    
    private var mockInterviewDao = MockInterviewDao()
    
    private var estimateLandmarkScoreTimer: Timer?
    
    private var tempFaceScores: [Int] = []
    
    private var tempEyesScores: [Int] = []
    
    func diSTTService(service: STTService) {
        MockInterviewManager.sttService = service
    }
    
    func prepareInterview() {
        isShowCautionView = false
        isShowFrame = true
        headerText = "顔認識中..."
        startRecIconAnimation()
        
        generateLandmarkReferencePoint()
    }
    
    func startInterview() {
        self.isDetected = true
        self.isShowFrame = false
        DispatchQueue.global(qos: .background).async {
            CameraService.shared.session.stopRunning()
        }
        headerText = "模擬面接中..."
        generateQuestion()
    }
    
    func predictScore(value: Int, criteria: Int) -> Int {
        if value < criteria + 10 && value > criteria - 10 {
            return Int.random(in: 85...95)
        } else if value < criteria + 20 && value > criteria - 20 {
            return Int.random(in: 90...100)
        } else if value < criteria + 30 && value > criteria - 30 {
            return Int.random(in: 80...89)
        } else if value < criteria + 40 && value > criteria - 40 {
            return Int.random(in: 70...79)
        } else if value < criteria + 60 && value > criteria - 60 {
            return Int.random(in: 60...69)
        } else if value < criteria + 80 && value > criteria - 80 {
            return Int.random(in: 50...59)
        } else if value < criteria + 120 && value > criteria - 120 {
            return Int.random(in: 40...49)
        } else {
            return Int.random(in: 10...39)
        }
    }
    
    func startEstimateLandmarkScore() {
        print("채점 시작")
        estimateLandmarkScoreTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { _ in
            self.detectLandmarks { res in
                guard let res else {
                    print("MockInterviewManager - estimateLandmarkScore 응답 데이터 비어있음")
                    return
                }
                
                if res.result {
                    guard let resDetection = res.detections else {
                        print("MockInterviewManager - estimateLandmarkScore 검출값이 비어있음")
                        return
                    }
                    
                    let faceTopXScore = self.predictScore(value: resDetection.face.top.x ?? MockInterviewInfo.shared.faceTopCoordinateXAvg,
                                                          criteria: MockInterviewInfo.shared.faceTopCoordinateXAvg)
                    let faceTopYScore = self.predictScore(value: resDetection.face.top.y ?? MockInterviewInfo.shared.faceTopCoordinateYAvg,
                                                          criteria: MockInterviewInfo.shared.faceTopCoordinateYAvg)
                    let faceBottomXScore = self.predictScore(value: resDetection.face.bottom.x ?? MockInterviewInfo.shared.faceBottomCoordinateXAvg,
                                                          criteria: MockInterviewInfo.shared.faceBottomCoordinateXAvg)
                    let faceBottomYScore = self.predictScore(value: resDetection.face.bottom.y ?? MockInterviewInfo.shared.faceBottomCoordinateYAvg,
                                                          criteria: MockInterviewInfo.shared.faceBottomCoordinateYAvg)
                    let faceRightXScore = self.predictScore(value: resDetection.face.right.x ?? MockInterviewInfo.shared.faceRightCoordinateXAvg,
                                                          criteria: MockInterviewInfo.shared.faceRightCoordinateXAvg)
                    let faceRightYScore = self.predictScore(value: resDetection.face.right.y ?? MockInterviewInfo.shared.faceRightCoordinateYAvg,
                                                          criteria: MockInterviewInfo.shared.faceRightCoordinateYAvg)
                    let faceLeftXScore = self.predictScore(value: resDetection.face.left.x ?? MockInterviewInfo.shared.faceLeftCoordinateXAvg,
                                                          criteria: MockInterviewInfo.shared.faceLeftCoordinateXAvg)
                    let faceLeftYScore = self.predictScore(value: resDetection.face.left.y ?? MockInterviewInfo.shared.faceLeftCoordinateYAvg,
                                                          criteria: MockInterviewInfo.shared.faceLeftCoordinateYAvg)
                    
                    self.tempFaceScores.append(faceTopXScore)
                    self.tempFaceScores.append(faceTopYScore)
                    self.tempFaceScores.append(faceBottomXScore)
                    self.tempFaceScores.append(faceBottomYScore)
                    self.tempFaceScores.append(faceRightXScore)
                    self.tempFaceScores.append(faceRightYScore)
                    self.tempFaceScores.append(faceLeftXScore)
                    self.tempFaceScores.append(faceLeftYScore)
                    
                    let eyesRightXScore = self.predictScore(value: resDetection.eyes.right.x ?? MockInterviewInfo.shared.rightEyeXAvg,
                                                          criteria: MockInterviewInfo.shared.rightEyeXAvg)
                    let eyesRightYScore = self.predictScore(value: resDetection.eyes.right.y ?? MockInterviewInfo.shared.rightEyeYAvg,
                                                          criteria: MockInterviewInfo.shared.rightEyeYAvg)
                    let eyesLeftXScore = self.predictScore(value: resDetection.eyes.left.x ?? MockInterviewInfo.shared.leftEyeXAvg,
                                                          criteria: MockInterviewInfo.shared.leftEyeXAvg)
                    let eyesLeftYScore = self.predictScore(value: resDetection.eyes.left.y ?? MockInterviewInfo.shared.leftEyeYAvg,
                                                          criteria: MockInterviewInfo.shared.leftEyeYAvg)
                    
                    self.tempEyesScores.append(eyesRightXScore)
                    self.tempEyesScores.append(eyesRightYScore)
                    self.tempEyesScores.append(eyesLeftXScore)
                    self.tempEyesScores.append(eyesLeftYScore)
                    
                } else {
                    self.tempFaceScores.append(0)
                    self.tempFaceScores.append(0)
                    self.tempFaceScores.append(0)
                    self.tempFaceScores.append(0)
                    self.tempFaceScores.append(0)
                    self.tempFaceScores.append(0)
                    self.tempFaceScores.append(0)
                    self.tempFaceScores.append(0)
                    
                    self.tempEyesScores.append(0)
                    self.tempEyesScores.append(0)
                    self.tempEyesScores.append(0)
                    self.tempEyesScores.append(0)
                }
            }
        })
    }
    
    func stopEstimate() {
        print("채점 중 ")
        estimateLandmarkScoreTimer?.invalidate()
        estimateLandmarkScoreTimer = nil
        
        let faceSum = tempFaceScores.reduce(0, +)
        if faceSum == 0 {
            MockInterviewInfo.shared.faceScores.append(0)
        } else {
            let faceAvg = faceSum / tempFaceScores.count
            MockInterviewInfo.shared.faceScores.append(faceAvg)
        }
        
        let eyesSum = tempEyesScores.reduce(0, +)
        if eyesSum == 0 {
            MockInterviewInfo.shared.eyesScores.append(0)
        } else {
            let eyesAvg = eyesSum / tempEyesScores.count
            MockInterviewInfo.shared.eyesScores.append(eyesAvg)
        }
        
        tempEyesScores = []
        tempFaceScores = []
        
        print("현재 Detections 점수")
        print("Face: \(MockInterviewInfo.shared.faceScores)")
        print("Eyes: \(MockInterviewInfo.shared.eyesScores)")
    }
    
    func generateLandmarkReferencePoint() {
        var timer: Timer?
        
        var countTimer = 1
        
        var faceDetections: [String: [Int]] = [
            "topX": [],
            "topY": [],
            "bottomX": [],
            "bottomY": [],
            "rightX": [],
            "rightY": [],
            "leftX": [],
            "leftY": [],
        ]
        
        var eyesDetections: [String: [Int]] = [
            "rightX": [],
            "rightY": [],
            "leftX": [],
            "leftY": [],
        ]
        
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { _ in
            self.detectLandmarks { res in
                guard let res else {
                    print("MockInterviewManager - generateLandmarkReferencePoint 응답 데이터 비어있음")
                    return
                }
                
                if res.result {
                    guard let resDetection = res.detections else {
                        print("MockInterviewManager - generateLandmarkReferencePoint 검출값이 비어있음")
                        return
                    }
                    
                    guard let faceTopX = resDetection.face.top.x,
                          let faceTopY = resDetection.face.top.y,
                          let faceBottomX = resDetection.face.bottom.x,
                          let faceBottomY = resDetection.face.bottom.y,
                          let faceLeftX = resDetection.face.left.x,
                          let faceLeftY = resDetection.face.left.y,
                          let faceRightX = resDetection.face.right.x,
                          let faceRightY = resDetection.face.right.y,
                          let eyesRightX = resDetection.eyes.right.x,
                          let eyesRightY = resDetection.eyes.right.y,
                          let eyesLeftX = resDetection.eyes.left.x,
                          let eyesLeftY = resDetection.eyes.left.y
                    else {
                        print("MockInterviewManager - gnerateLandmarkReferencePoint nil값이 존재")
                        return
                    }
                    
                    faceDetections["topX"]?.append(faceTopX)
                    faceDetections["topY"]?.append(faceTopY)
                    faceDetections["bottomX"]?.append(faceBottomX)
                    faceDetections["bottomY"]?.append(faceBottomY)
                    faceDetections["rightX"]?.append(faceRightX)
                    faceDetections["rightY"]?.append(faceRightY)
                    faceDetections["leftX"]?.append(faceLeftX)
                    faceDetections["leftY"]?.append(faceLeftY)
                    eyesDetections["rightX"]?.append(eyesRightX)
                    eyesDetections["rightY"]?.append(eyesRightY)
                    eyesDetections["leftX"]?.append(eyesLeftX)
                    eyesDetections["leftY"]?.append(eyesLeftY)
                    
                    countTimer += 1
                    
                    if countTimer > 3 {
                        timer?.invalidate()
                        timer = nil
                        
                        let faceTopXAvg = (faceDetections["topX"]?.reduce(0, +) ?? 1) / 3
                        MockInterviewInfo.shared.faceTopCoordinateXAvg = faceTopXAvg
                        
                        let faceTopYAvg = (faceDetections["topY"]?.reduce(0, +) ?? 1) / 3
                        MockInterviewInfo.shared.faceTopCoordinateYAvg = faceTopYAvg
                        
                        let faceBottomXAvg = (faceDetections["bottomX"]?.reduce(0, +) ?? 1) / 3
                        MockInterviewInfo.shared.faceBottomCoordinateXAvg = faceBottomXAvg
                        
                        let faceBottomYAvg = (faceDetections["bottomY"]?.reduce(0, +) ?? 1) / 3
                        MockInterviewInfo.shared.faceBottomCoordinateYAvg = faceBottomYAvg
                        
                        let faceRightXAvg = (faceDetections["rightX"]?.reduce(0, +) ?? 1) / 3
                        MockInterviewInfo.shared.faceRightCoordinateXAvg = faceRightXAvg
                        
                        let faceRightYAvg = (faceDetections["rightY"]?.reduce(0, +) ?? 1) / 3
                        MockInterviewInfo.shared.faceRightCoordinateYAvg = faceRightYAvg
                        
                        let faceLeftXAvg = (faceDetections["leftX"]?.reduce(0, +) ?? 1) / 3
                        MockInterviewInfo.shared.faceLeftCoordinateXAvg = faceLeftXAvg
                        
                        let faceLeftYAvg = (faceDetections["leftY"]?.reduce(0, +) ?? 1) / 3
                        MockInterviewInfo.shared.faceLeftCoordinateYAvg = faceLeftYAvg
                        
                        let eyesRightXAvg = (eyesDetections["rightX"]?.reduce(0, +) ?? 1) / 3
                        MockInterviewInfo.shared.rightEyeXAvg = eyesRightXAvg
                        
                        let eyesRightYAvg = (eyesDetections["rightY"]?.reduce(0, +) ?? 1) / 3
                        MockInterviewInfo.shared.rightEyeYAvg = eyesRightYAvg
                        
                        let eyesLeftXAvg = (eyesDetections["leftX"]?.reduce(0, +) ?? 1) / 3
                        MockInterviewInfo.shared.leftEyeXAvg = eyesLeftXAvg
                        
                        let eyesLeftYAvg = (eyesDetections["leftY"]?.reduce(0, +) ?? 1) / 3
                        MockInterviewInfo.shared.leftEyeYAvg = eyesLeftYAvg
                        
                        print("face top x avg = \(MockInterviewInfo.shared.faceTopCoordinateXAvg)")
                        print("face top y avg = \(MockInterviewInfo.shared.faceTopCoordinateYAvg)")
                        print("face bottom x avg = \(MockInterviewInfo.shared.faceBottomCoordinateXAvg)")
                        print("face bottom y avg = \(MockInterviewInfo.shared.faceBottomCoordinateYAvg)")
                        print("face right x avg = \(MockInterviewInfo.shared.faceRightCoordinateXAvg)")
                        print("face right y avg = \(MockInterviewInfo.shared.faceRightCoordinateYAvg)")
                        print("face left x avg = \(MockInterviewInfo.shared.faceLeftCoordinateXAvg)")
                        print("face left y avg = \(MockInterviewInfo.shared.faceLeftCoordinateYAvg)")
                        print("eyes left x avg = \(MockInterviewInfo.shared.leftEyeXAvg)")
                        print("eyes left y avg = \(MockInterviewInfo.shared.leftEyeYAvg)")
                        print("eyes right x avg = \(MockInterviewInfo.shared.rightEyeXAvg)")
                        print("eyes right y avg = \(MockInterviewInfo.shared.rightEyeYAvg)")
                        
                        self.startInterview()
                    }
                    
                    
                } else {
                    print("MockInterviewManager - generateLandmarkReferencePoint 응답 결과 false")
                }
            }
        })
    }
    
    func isBase64StringValidImage(base64String: String) -> Bool {
        guard let imageData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
            return false
        }
        
        guard let image = UIImage(data: imageData) else {
            return false
        }
        
        return image.size.width > 0 && image.size.height > 0
    }
    
    func detectLandmarks(completion: @escaping (DetectLandmarksResponse?) -> Void) {
        CameraService.shared.captureFrame()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let encodedData = CameraService.shared.frameToPNGData()?.base64EncodedString()
            
            if !self.isBase64StringValidImage(base64String: encodedData ?? "") {
                print("사진으로 사용할 수 없는 base64 문자열")
                return
            }
            
            
            let params = ["encoded_frame_data": encodedData]
            
            HTTPRequest.shared.post(path: "/detect/landmarks",
                                    type: DetectLandmarksResponse.self,
                                    body: params) { data in
                
                guard let data else {
                    print("MockInterviewManager - detectLandmark data == nil")
                    return
                }
                
                completion(data)
            }
        }
    }
    
    func generateQuestion(text: String = "") {
        if questionCount < 1 {
            let conversationStartRequestBody = ConversationStartRequest(
                company_name: MockInterviewInfo.shared.companyName,
                interview_type: MockInterviewInfo.shared.interviewType,
                company_type: MockInterviewInfo.shared.companyType,
                career_type: MockInterviewInfo.shared.careerType)
            
            HTTPRequest.shared.post(path: "/conversation/start", type: GPTResponse.self, body: conversationStartRequestBody) { data in
                guard let data else {
                    print("Start - GPT 데이터 오류")
                    return
                }
                
                print("generate question start --")
                for message in data.messages {
                    print("role: \(message.role), content: \(message.content)")
                    if message.role == "system" {
                        MockInterviewInfo.shared.systemMessage = message.content
                    } else if message.role == "assistant" {
                        MockInterviewInfo.shared.assistantMessages.append(message.content)
                    } else if message.role == "user" {
                        MockInterviewInfo.shared.userMessages.append(message.content)
                    }
                }
                
                if data.messages[data.messages.count - 1].role == "assistant" {
                    let answer = data.messages[data.messages.count - 1].content
                    
                    TTSModel.shared.speech(text: answer)
                }
            }
        } else if questionCount < 7 {
            var messages: [GPTRequest] = []
            
            messages.append(GPTRequest(role: "system", 
                                       content: MockInterviewInfo.shared.systemMessage))
            messages.append(GPTRequest(role: "assistant",
                                       content: MockInterviewInfo.shared.assistantMessages[MockInterviewInfo.shared.assistantMessages.count - 1]))
            if questionCount == 6 {
                messages.append(GPTRequest(role: "user",
                                           content: "\(text)「次は最後の質問をお願いします。」"))
            } else {
                messages.append(GPTRequest(role: "user",
                                           content: text))
            }
            
            MockInterviewInfo.shared.userMessages.append(text)
            
            for message in messages {
                print("DEBUG - \(message.role), \(message.content)")
            }
            
            HTTPRequest.shared.post(path: "/conversation/continue", type: GPTResponse.self, body: messages) { data in
                guard let data else {
                    print("Continue - GPT 데이터 오류")
                    return
                }
                
                print("generate question continue --")
                print("role: \(data.messages[data.messages.count - 1].role), content: \(data.messages[data.messages.count - 1].content)")
                MockInterviewInfo.shared.assistantMessages.append(data.messages[data.messages.count - 1].content)
                
                if data.messages[data.messages.count - 1].role == "assistant" {
                    let answer = data.messages[data.messages.count - 1].content
                    
                    TTSModel.shared.speech(text: answer)
                }
            }
        } else {
            var messages: [GPTRequest] = []
            
            print(MockInterviewInfo.shared.userMessages)
            
            for userMessage in MockInterviewInfo.shared.userMessages {
                messages.append(GPTRequest(role: "user", content: userMessage))
            }
            messages.append(GPTRequest(role: "user",
                                       content: "面接が終わりました。この面接を評価してください。"))
            
            
            
            HTTPRequest.shared.post(path: "/conversation/continue", type: GPTResponse.self, body: messages) { data in
                guard let data else {
                    print("End - GPT 데이터 오류")
                    return
                }
                
                print("generate question continue last --")
                MockInterviewInfo.shared.interviewStoryFeedback = data.messages[data.messages.count - 1].content
                print("feedback: \(data.messages[data.messages.count - 1].content)")
                self.saveInterviewResult()
                self.navigateToResult = true
                
                MockInterviewInfo.shared.initialize()
            }
        }
        questionCount += 1
    }
    
    func saveInterviewResult() {
        let info = MockInterviewInfo.shared
        
        var icon = "graduationcap.fill"
        if let interviewType = InterviewType(rawValue: info.interviewType) {
            icon = interviewType.icon
        }
        
        info.calcTotalScore()
        
        mockInterviewDao.add(
            companyName: info.companyName,
            interviewTypeIcon: icon,
            totalScore: info.mockInterviewScore,
            interviewFeedback: info.interviewStoryFeedback,
            questions: info.assistantMessages,
            answers: info.userMessages,
            eyesScores: info.eyesScores,
            faceScores: info.faceScores,
            answerSpeedScores: info.answerSpeedScores)
    }
    
    func findNumbersInString(string: String) -> [Int] {
            let numberCharacterSet = CharacterSet.decimalDigits
            let components = string.components(separatedBy: numberCharacterSet.inverted)
            let numbersInString = components.compactMap { Int($0) }
            return numbersInString
        }
    
    func startRecIconAnimation() {
        withAnimation(.linear(duration: 1).repeatForever()) {
            self.recIconOpacity -= 1
        }
    }
    
    class TTSModel: NSObject, AVSpeechSynthesizerDelegate {
        static let shared = TTSModel()
        
        private let synthesizer = AVSpeechSynthesizer()
        
        private override init() {
            AVSpeechSynthesisVoice.speechVoices()
        }
        
        func speech(text: String) {
            if text.isEmpty {
                return
            }

            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = 0.5
            utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")

            synthesizer.delegate = self
            synthesizer.speak(utterance)
        }

        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                sttService?.startRecord()
                
                
            }
        }
    }
}
