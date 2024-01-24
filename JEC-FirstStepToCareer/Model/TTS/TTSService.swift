//
//  TTSService.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import SwiftUI
import AVFoundation

class TTSService {
    let languages = ["English", "Japanese", "Korean"]
    
    private let synthesizer = AVSpeechSynthesizer()
    
    var text = ""
    
    func read() {
        if text.isEmpty {
            return
        }
        
        var languageCode = "ja-JP"
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)

        synthesizer.speak(utterance)
        
        text = ""
    }
}
