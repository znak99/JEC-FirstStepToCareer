//
//  DetectFaceResponse.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/05.
//

import Foundation

struct DetectFaceResponse: Decodable {
    let result: Bool
    let detections: DetectionsResponse?
}
