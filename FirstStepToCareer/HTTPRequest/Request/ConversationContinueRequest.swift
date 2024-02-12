//
//  ConversationContinueRequest.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/26.
//

import Foundation

struct ConversationContinueRequest: Encodable {
    let messages: [GPTRequest]
}

struct GPTRequest: Encodable {
    let role: String
    let content: String
}
