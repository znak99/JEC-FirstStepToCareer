//
//  GPTResponse.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/14.
//

import Foundation

struct GPTResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let usage: GPTUsage
    let choices: [GPTChoices]
}

struct GPTUsage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

struct GPTChoices: Codable {
    let message: GPTMessage
    let finish_reason: String
    let index: Int
}
