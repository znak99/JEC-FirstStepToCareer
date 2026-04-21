//
//  STTService.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/14.
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
    
    func startRecord() {
        checkAnswerStartTime()
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch let error as NSError {
            print(error)
        }
        do {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            text = ""
            try audioEngine.start()
            
            if let recognitionRequest = recognitionRequest {
                transcription(recognizer: recognizer,
                              request: recognitionRequest)
            }
            isRecording = true
            print("STT start")
        } catch {
            print(error)
        }
    }
    
    func stopRecord() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isRecording = false
        print("STT stop")
    }
    
    private func transcription(recognizer: SFSpeechRecognizer?, request: SFSpeechAudioBufferRecognitionRequest) {
        recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                self.text = result.bestTranscription.formattedString
            } else if let error = error {
                print(error)
            }
        }
    }
    
    private func checkAnswerStartTime() {
        var time: Float = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            time += 0.1
            if self.text != "" {
                self.checkAnswerFinished()
                self.calculateAnswerSpeedScore(time: time)
                timer.invalidate()
            }
        }
    }
    
    private func checkAnswerFinished() {
        var temp = ""
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
            if temp == self.text {
                self.stopRecord()
                timer.invalidate()
            } else {
                temp = self.text
            }
        }
    }
    
    private func calculateAnswerSpeedScore(time: Float) {
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
}
