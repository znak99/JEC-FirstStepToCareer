//
//  GPTInfo.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/14.
//

import Foundation

class GPTInfo {
    private init() {}
    
    static let model = "gpt-3.5-turbo-0125"
    
    static let apikey = ""
    
    static let url = "https://api.openai.com/v1/chat/completions"
    
    static let initializeSystemContent = """
        You are an interviewer for a Japanese company.You can only speak Japanese.Do not use English or any
        other language.You only use colloquial language.Understand the user's answers and ask questions to user
        about the interview.If user's answer is irrelevant or incomprehensible to the interview,
        say "回答を理解できませんでした。" and ask another question.You have to ask at least 6 interview questions until user say 'Estimate this interview in Japanese'.
    """
    
    static func generatePrompt(companyName: String, companyType: String, interviewType: String, careerType: String) -> String {
        let prompt = """
            You are an interviewer for a Japanese company called '\(companyName)'.
            The '\(companyName)' is a \(companyType) company.
            User wants the \(careerType) section of \(interviewType == "新卒" ? "your company's new recruitment." : "hiring experienced employees of your company.")
            Start the interview now. The first question is '自己PRをお願いします'.
            Conduct an interview on this subject
        """
        
        return prompt
    }
}
