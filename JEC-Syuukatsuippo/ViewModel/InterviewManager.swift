//
//  InterviewManager.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/13.
//

import Foundation
import SwiftUI
import Combine
import Vision
import AVFAudio
import Speech
import Photos

class InterviewManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    // MARK: - Flow controlers
    @Published var isStartGenerateReferencePoint = false
    @Published var isReferencePointGenerated = false
    
    @Published var isRecording = false
    
    @Published var isShowLoadingIndicator = false
    
    @Published var isNavigateToInterviewResultView = false
    
    @Published var isDetectingFaceRect = false
    
    @Published var isShowQuitAlert = false
    
    @Published var isWillDismiss = false
    
    @Published var isRegenerateQuestion = false
    
    @Published var questionCount = 0
    
    // MARK: - Camera properties
    @Published var cameraService = CameraService()
    @Published var previewSize = CGRect(origin: .zero, size: UIScreen.main.bounds.size)
    
    // MARK: - UI properties
    @Published var recIconOpacity: CGFloat = 1
    @Published var headerText = "模擬面接準備中..."
    
    var statusMessage: String {
        if isGeneratingQuestion && !isRecording {
            return "質問を生成しています..."
        } else if !isGeneratingQuestion && !isRecording && questionCount > 7 {
            return "面接を終わります。\nお疲れ様でした。"
        } else if !isGeneratingQuestion && isRecording {
            return "音声を録音しています..."
        } else if !isGeneratingQuestion && !isRecording {
            return "質問を読み上げています..."
        } else if isGeneratingQuestion && !isRecording && questionCount > 7 {
            return "面接を評価しています..."
        }
        
        return ""
    }
    
    // MARK: - Cancellables
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - GPT
    private var conversations: [GPTMessage] = []
    
    // MARK: - TTS
    let synthesizer = AVSpeechSynthesizer()
    
    @Published var isGeneratingQuestion = false
    @Published var isReplayQuestion = false
    @Published var isSpeaking = false
    
    // MARK: - DB
    private let mockInterviewDao = MockInterviewDAO()
    
    // MARK: - Temporary variables
    private var faceRects: [CGRect] = []
    
    @Published var interviewResult: MockInterview = MockInterview()
    
    private var isCanNavigate = false
    
    @Published var videoUrl: URL?
    @Published var isVideoReady = false
    @Published var isVideoDownloaded = false
    
    override init() {
        AVSpeechSynthesisVoice.speechVoices()
    }
    
    // MARK: - Actions
    func prepareInterview() {
        withAnimation {
            self.isStartGenerateReferencePoint = true
        }
        
        self.startRecIconAnimation()
        self.headerText = "顔認識中..."
        
        generateFaceReferencPoints()
    }
    
    func startInterview() {
        withAnimation {
            self.isReferencePointGenerated = true
        }
        
        self.headerText = "模擬面接中..."
        
        startConversation()
    }
    
    func quitInterview() {
        isShowLoadingIndicator = true
        saveConversationsOnTemp()
        saveInterviewOnDB()
        
        InterviewInfoTemp.shared.clear()
        
        let lastElement = mockInterviewDao.getAll().last ?? MockInterview()
        interviewResult = lastElement
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if self.isCanNavigate {
                timer.invalidate()
                
                self.isShowLoadingIndicator = false
                self.isNavigateToInterviewResultView = true
            }
        }
    }
    
    func dismissAction() {
        isWillDismiss = true
        for cancellable in cancellables {
            cancellable.cancel()
        }
        
        synthesizer.pauseSpeaking(at: .immediate)
    }
    
    func generateFaceReferencPoints() {
        faceRects = []
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.cameraService.takePhoto { imageData in
                guard let uiImage = UIImage(data: imageData) else {
                    return
                }
                
                self.detectFaceRectangle(image: uiImage)
                
                if self.faceRects.count > 10 {
                    InterviewInfoTemp.shared.faceRectangleAvg = self.averageRect(rects: self.faceRects)
                    
                    if InterviewInfoTemp.shared.faceRectangleAvg != .zero {
                        timer.invalidate()
                        
                        self.startInterview()
                        
                    }
                }
            }
        }
    }
    
    func generateFaceRect() {
        faceRects = []
        isCanNavigate = false
        isDetectingFaceRect = true
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            self.cameraService.takePhoto { imageData in
                guard let uiImage = UIImage(data: imageData) else {
                    return
                }
                
                self.detectFaceRectangle(image: uiImage)
                
                if !self.isDetectingFaceRect {
                    timer.invalidate()
                    
                    self.generateFaceScore()
                }
            }
        }
    }
    
    func generateFaceScore() {
        if faceRects.isEmpty {
            InterviewInfoTemp.shared.faceScores.append(0)
            return
        }
        var scores: [Int] = []
        
        let standard = InterviewInfoTemp.shared.faceRectangleAvg
        for rect in faceRects {
            let deltaX = abs(standard.origin.x - rect.origin.x)
            let deltaY = abs(standard.origin.y - rect.origin.y)
            let widthDiff = abs(standard.width - rect.width)
            let heightDiff = abs(standard.height - rect.height)
            
            let total = deltaX + deltaY + widthDiff + heightDiff
            
            scores.append(calculateRectScore(total: total))
        }
        
        let scoreAvg = scores.reduce(0, +) / scores.count
        InterviewInfoTemp.shared.faceScores.append(scoreAvg)
        isCanNavigate = true
    }
    
    func saveConversationsOnTemp() {
        conversations.removeFirst()
        conversations.removeFirst()
        
        for conversation in conversations {
            InterviewInfoTemp.shared.conversations.append(GPTMessage(role: conversation.role,
                                                                     content: conversation.content))
        }
    }
    
    func saveInterviewOnDB() {
        
        let temp = InterviewInfoTemp.shared
        
        let icon = InterviewType(rawValue: temp.interviewType)?.icon ?? InterviewType.newcomer.icon
        temp.calcInterviewScore()
        
        var questions: [String] = []
        for conversation in temp.conversations {
            if conversation.role == "assistant" {
                questions.append(conversation.content)
            }
        }
        
        var answers: [String] = []
        for conversation in temp.conversations {
            if conversation.role == "user" {
                answers.append(conversation.content)
            }
        }
        
        while (temp.eyesScores.count < 7) {
            var geneatedScore = temp.eyesScores.last ?? 0 + Int.random(in: -5...5)
            if geneatedScore > 100 {
                geneatedScore = Int.random(in: 95...100)
            }
            temp.eyesScores.append(geneatedScore)
        }
        
        while (temp.faceScores.count < 7) {
            var geneatedScore = temp.faceScores.last ?? 0 + Int.random(in: -5...5)
            if geneatedScore > 100 {
                geneatedScore = Int.random(in: 95...100)
            }
            temp.faceScores.append(geneatedScore)
        }
        
        
        mockInterviewDao.add(companyName: temp.companyName,
                             interviewTypeIcon: icon,
                             totalScore: temp.interviewScore,
                             interviewFeedback: temp.interviewFeedback,
                             questions: questions,
                             answers: answers,
                             eyesScores: temp.eyesScores,
                             faceScores: temp.faceScores,
                             answerSpeedScores: temp.answerSpeedScores)
    }
    
    func downloadVideo() {
        isVideoDownloaded = false
        
        guard let videoUrl else {
            isVideoDownloaded = true
            return
        }
        
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
        } completionHandler: { _, error in
            if let error {
                print(error)
            }
        }
    }
    
    // MARK: - Detections
    func detectFaceRectangle(image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            return
        }
        
        let request = VNDetectFaceRectanglesRequest { req, err in
            if err != nil {
                return
            }
            
            guard let observations = req.results as? [VNFaceObservation] else {
                return
            }
            
            var faceRectsTemp: [CGRect] = []
            for observation in observations {
                let boundingBox = observation.boundingBox
                let faceRect = CGRect(x: boundingBox.origin.x * image.size.width,
                                      y: (1 - boundingBox.origin.y - boundingBox.height) * image.size.height,
                                      width: boundingBox.width * image.size.width,
                                      height: boundingBox.height * image.size.height)
                faceRectsTemp.append(faceRect)
            }
            
            if faceRectsTemp.count > 1 {
                return
            }
            
            if let detectedData = faceRectsTemp.first {
                self.faceRects.append(detectedData)
            }
        }
        
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: .up, options: [:])

        do {
            try requestHandler.perform([request])
        } catch {
            print(error)
        }
    }
    
    // MARK: - Requests
    func startConversation() {
        isGeneratingQuestion = true
        isRecording = false
        
        let systemContent = GPTMessage(role: "system", content: GPTInfo.initializeSystemContent)
        let prompt = GPTMessage(role: "user", content: GPTInfo.generatePrompt(companyName: InterviewInfoTemp.shared.companyName,
                                                                              companyType: InterviewInfoTemp.shared.companyType,
                                                                              interviewType: InterviewInfoTemp.shared.interviewType,
                                                                              careerType: InterviewInfoTemp.shared.careerType))
        
        conversations.append(systemContent)
        conversations.append(prompt)
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(GPTInfo.apikey)"
        ]
        
        let gptRequest = GPTRequest(
            model: "gpt-3.5-turbo-0125",
            messages: conversations,
            temperature: 0.2,
            max_tokens: 256
        )
        
        let encoder = JSONEncoder()
        guard let body = try? encoder.encode(gptRequest) else {
            self.isGeneratingQuestion = false
            return
        }
        
        let apiUrl = URL(string: GPTInfo.url)!
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: GPTResponse.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.isGeneratingQuestion = false
                    print(error)
                }
            }, receiveValue: { response in
                let role = response.choices.first?.message.role ?? "assistant"
                let content = response.choices.first?.message.content ?? "エラーが発生しました。"
                
                print("content: \(content)")
                
                if !content.isEmpty {
                    self.conversations.append(GPTMessage(role: role, content: content))
                    DispatchQueue.main.async {
                        self.speak(text: content)
                        self.questionCount += 1
                        print("Q\(self.questionCount). \(content)")
                        self.isGeneratingQuestion = false
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    func continueConversation(message: String) {
        isGeneratingQuestion = true
        isRecording = false
        
        conversations.append(GPTMessage(role: "user", content: message))
        print("A\(self.questionCount). \(message)")
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(GPTInfo.apikey)"
        ]
        
        let gptRequest = GPTRequest(
            model: "gpt-3.5-turbo-0125",
            messages: conversations,
            temperature: 0.2,
            max_tokens: 256
        )
        
        let encoder = JSONEncoder()
        guard let body = try? encoder.encode(gptRequest) else {
            self.isGeneratingQuestion = false
            return
        }
        
        let apiUrl = URL(string: GPTInfo.url)!
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: GPTResponse.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.isGeneratingQuestion = false
                    print(error)
                }
            }, receiveValue: { response in
                let role = response.choices.first?.message.role ?? "assistant"
                let content = response.choices.first?.message.content ?? "エラーが発生しました。"
                if !content.isEmpty {
                    self.conversations.append(GPTMessage(role: role, content: content))
                    DispatchQueue.main.async {
                        self.speak(text: content)
                        self.questionCount += 1
                        self.isGeneratingQuestion = false
                        print("Q\(self.questionCount). \(content)")
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    func regenerateConversation() {
        isGeneratingQuestion = true
        isRecording = false
        
        conversations.append(GPTMessage(role: "user", content: "Regenerate question in Japanese"))
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(GPTInfo.apikey)"
        ]
        
        let gptRequest = GPTRequest(
            model: "gpt-3.5-turbo-0125",
            messages: conversations,
            temperature: 0.2,
            max_tokens: 256
        )
        
        let encoder = JSONEncoder()
        guard let body = try? encoder.encode(gptRequest) else {
            self.isGeneratingQuestion = false
            return
        }
        
        let apiUrl = URL(string: GPTInfo.url)!
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: GPTResponse.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.isGeneratingQuestion = false
                    print(error)
                }
            }, receiveValue: { response in
                let role = response.choices.first?.message.role ?? "assistant"
                let content = response.choices.first?.message.content ?? "エラーが発生しました。"
                if !content.isEmpty {
                    DispatchQueue.main.async {
                        let _ = self.conversations.popLast()
                        let _ = self.conversations.popLast()
                        self.conversations.append(GPTMessage(role: role, content: content))
                        self.speak(text: content)
                        self.isGeneratingQuestion = false
                        print("Q\(self.questionCount). \(content)")
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    func finishConversation(message: String) {
        isGeneratingQuestion = true
        isRecording = false
        conversations.append(GPTMessage(role: "user", content: message))
        print("A\(self.questionCount). \(message)")
        conversations.append(GPTMessage(role: "user", content: "Estimate this interview in Japanese"))
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(GPTInfo.apikey)"
        ]
        
        let gptRequest = GPTRequest(
            model: "gpt-3.5-turbo-0125",
            messages: conversations,
            temperature: 0.2,
            max_tokens: 256
        )
        
        let encoder = JSONEncoder()
        guard let body = try? encoder.encode(gptRequest) else {
            self.isGeneratingQuestion = false
            return
        }
        
        let apiUrl = URL(string: GPTInfo.url)!
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: GPTResponse.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.isGeneratingQuestion = false
                    print(error)
                }
            }, receiveValue: { response in
                let content = response.choices.first?.message.content ?? "エラーが発生しました。"
                if !content.isEmpty {
                    print("Feedback: \(content)")
                    DispatchQueue.main.async {
                        self.speak(text: "以上で面接を終わります。お疲れ様でした。")
                        let _ = self.conversations.popLast()
                        InterviewInfoTemp.shared.interviewFeedback = content
                        self.questionCount += 1
                        self.isGeneratingQuestion = false
                    }
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - TTS
    func speak(text: String) {
        if text.isEmpty {
            return
        }
        
        isSpeaking = true
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .voicePrompt, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print(error.localizedDescription)
        }
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        if synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")

        synthesizer.delegate = self
        synthesizer.speak(utterance)
        print("TTS start")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            print("TTS finish")
            self.isSpeaking = false
            self.isReplayQuestion = false
            self.isRegenerateQuestion = false
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.record, mode: .measurement, options: [.mixWithOthers])
                try session.setActive(true)
            } catch {
                print(error.localizedDescription)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.questionCount < 8 {
                self.isRecording = true
            } else {
                self.quitInterview()
            }
        }
    }
    
    func replayQuestion() {
        isRecording = false
        
        let question = conversations.last?.content ?? "もう一度質問を読み上げる途中でエラー発生"
        synthesizer.pauseSpeaking(at: .immediate)
        speak(text: question)
    }
    
    // MARK: - Camera functions
    func reducePreviewSize() {
        withAnimation {
            previewSize = CGRect(x: UIScreen.main.bounds.size.width / 1.5,
                                 y: UIScreen.main.bounds.size.height / 6.5,
                                 width: UIScreen.main.bounds.size.width / 3.5,
                                 height: (UIScreen.main.bounds.size.width / 3.5) * 1.65)
        }
    }
    
    // MARK: - Calculate functions
    func averageRect(rects: [CGRect]) -> CGRect {
        guard !rects.isEmpty else {
            return .zero
        }

        var totalOriginX: CGFloat = 0.0
        var totalOriginY: CGFloat = 0.0
        var totalWidth: CGFloat = 0.0
        var totalHeight: CGFloat = 0.0

        for rect in rects {
            totalOriginX += rect.origin.x
            totalOriginY += rect.origin.y
            totalWidth += rect.size.width
            totalHeight += rect.size.height
        }

        let averageOriginX = totalOriginX / CGFloat(rects.count)
        let averageOriginY = totalOriginY / CGFloat(rects.count)
        let averageWidth = totalWidth / CGFloat(rects.count)
        let averageHeight = totalHeight / CGFloat(rects.count)

        let averageRect = CGRect(x: averageOriginX, y: averageOriginY, width: averageWidth, height: averageHeight)
        
        return averageRect
    }
    
    func calculateAnswerSpeedScore(time: Float) {
        if time > 5.0 {
            InterviewInfoTemp.shared.answerSpeedScores.append(Int.random(in: 20..<60))
        } else if time > 4.0 {
            InterviewInfoTemp.shared.answerSpeedScores.append(Int.random(in: 60..<70))
        } else if time > 3.0 {
            InterviewInfoTemp.shared.answerSpeedScores.append(Int.random(in: 70..<80))
        } else if time > 2.0 {
            InterviewInfoTemp.shared.answerSpeedScores.append(Int.random(in: 80..<90))
        } else if time > 1.0 {
            InterviewInfoTemp.shared.answerSpeedScores.append(Int.random(in: 95...100))
        } else {
            InterviewInfoTemp.shared.answerSpeedScores.append(Int.random(in: 85..<95))
        }
    }
    
    func calculateRectScore(total: CGFloat) -> Int {
        let totalFloat = Float(total)
        
        if totalFloat < 200 {
            return Int.random(in: 90...100)
        } else if totalFloat < 350 {
            return Int.random(in: 80..<90)
        } else if totalFloat < 500 {
            return Int.random(in: 70..<80)
        } else if totalFloat < 700 {
            return Int.random(in: 60..<70)
        } else {
            return Int.random(in: 20..<60)
        }
    }
    
    // MARK: - UI Animations
    func startRecIconAnimation() {
        withAnimation(.linear(duration: 1).repeatForever()) {
            self.recIconOpacity -= 1
        }
    }
}
