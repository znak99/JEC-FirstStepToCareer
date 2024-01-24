//
//  STTService.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import SwiftUI
import Speech

class STTService {
    let languages = ["English", "Japanese", "Korean"]
    
    private let japaneseRecognizer : SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var audioEngine = AVAudioEngine()
    
    init() {
        japaneseRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    }
    
    @Published var text = ""
    @Published var isRecording = false
    @Published var isSTTDisable = false
    
    func startRecord() {
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
                transcription(recognizer: japaneseRecognizer,
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
