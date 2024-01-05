//
//  AppConstants.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/29.
//

import Foundation

class AppConstants {
    private static let url = "https://port-0-firststeptocareersample-1fk9002blqz3suv5.sel5.cloudtype.app"
    
    private init() {}
    
    static func requestUrl(path: String = "") -> URL? {
        var formattedPath = path
        
        if formattedPath.hasPrefix("/") {
            formattedPath.removeFirst()
        }
        
        if formattedPath.hasSuffix("/") {
            formattedPath.removeLast()
        }
        
        let urlString = "\(url)/\(path)"
        
        return URL(string: urlString)
    }
}
