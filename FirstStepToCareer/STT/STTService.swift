//
//  STTService.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/02/09.
//

import Foundation
import Speech

class STTService: ObservableObject {
    private let recognizer : SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var audioEngine = AVAudioEngine()
    
    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    }
    
    @Published var text = ""
    @Published var isRecording = false
    @Published var isSTTDisable = false
    @Published var isSTTStopped = false
    
    func checkAnswerStartTime() {
        var time: Float = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            time += 0.1
            if self.text != "" {
                self.checkAnswerFinished()
                self.calculateAnswerSpeedScore(time: time)
                timer.invalidate()
                print("말하기 시작 시간 \(time)")
                print("MockinterviewInfo.answerSpeedScores \(MockInterviewInfo.shared.answerSpeedScores)")
            }
        }
    }
    
    func calculateAnswerSpeedScore(time: Float) {
        if time > 5.0 {
            MockInterviewInfo.shared.answerSpeedScores.append(Int.random(in: 20..<60))
        } else if time > 4.0 {
            MockInterviewInfo.shared.answerSpeedScores.append(Int.random(in: 60..<70))
        } else if time > 3.0 {
            MockInterviewInfo.shared.answerSpeedScores.append(Int.random(in: 70..<80))
        } else if time > 2.0 {
            MockInterviewInfo.shared.answerSpeedScores.append(Int.random(in: 80..<90))
        } else if time > 1.0 {
            MockInterviewInfo.shared.answerSpeedScores.append(Int.random(in: 95...100))
        } else {
            MockInterviewInfo.shared.answerSpeedScores.append(Int.random(in: 85..<95))
        }
    }
    
    func checkAnswerFinished() {
        var temp = ""
        var isFisttime = true
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
            if !isFisttime {
                if temp == self.text {
                    self.stopRecord()
                    timer.invalidate()
                    print("stt stopped")
                } else {
                    temp = self.text
                    print("stt continue")
                }
            }
            isFisttime = false
        }
    }
    
    func startRecord() {
        checkAnswerStartTime()
        do {
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            text = ""
            
            if let recognitionRequest = recognitionRequest {
                transcription(recognizer: recognizer,
                              request: recognitionRequest)
            }
            isRecording = true
        } catch {
            print("Audio Engine error: \(error)")
        }
    }
    
    func stopRecord() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isRecording = false
        isSTTStopped = true
    }
    
    func transcription(recognizer: SFSpeechRecognizer?,
                       request: SFSpeechAudioBufferRecognitionRequest) {
        recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                self.text = result.bestTranscription.formattedString
            } else if let error = error {
                print("Recognition error: \(error)")
            }
        }
    }
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus == .authorized {
                print("Speech recognition authorized")
            } else {
                print("Speech recognition not authorized")
                self.isSTTDisable.toggle()
            }
        }
    }
}
