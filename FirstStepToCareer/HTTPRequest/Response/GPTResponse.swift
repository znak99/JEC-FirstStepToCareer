//
//  GPTResponse.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import Foundation

struct GPTResponse: Decodable {
    let messages: [MessageResponse]
}

struct MessageResponse: Decodable {
    let role: String
    let content: String
}
