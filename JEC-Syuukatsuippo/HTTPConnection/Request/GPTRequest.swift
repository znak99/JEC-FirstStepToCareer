//
//  GPTRequest.swift
//  JEC-Syuukatsuippo
//
//  Created by SeungWoo Hong on 2024/02/14.
//

import Foundation

struct GPTRequest: Codable {
    let model: String
    let messages: [GPTMessage]
    let temperature: Double
    let max_tokens: Int
}
