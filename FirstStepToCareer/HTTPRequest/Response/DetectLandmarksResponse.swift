//
//  DetectFaceResponse.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/05.
//

import Foundation

struct DetectLandmarksResponse: Decodable {
    let result: Bool
    let detections: DetectionsResponse?
}

struct DetectionsResponse: Decodable {
    let face: FaceDetections
    let eyes: EyesDetections
}

struct FaceDetections: Decodable {
    let top: LandmarkAxis
    let bottom: LandmarkAxis
    let right: LandmarkAxis
    let left: LandmarkAxis
}

struct EyesDetections: Decodable {
    let left: LandmarkAxis
    let right: LandmarkAxis
}

struct LandmarkAxis: Decodable {
    let x: Int?
    let y: Int?
}
