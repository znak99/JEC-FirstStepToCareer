//
//  HTTPRequest.swift
//  FirstStepToCareer
//
//  Created by SeungWoo Hong on 2024/01/24.
//

import Foundation

class HTTPRequest {
    
    static let shared = HTTPRequest()
    
    private let domain = "https://port-0-firststeptocareersample-1fk9002blqz3suv5.sel5.cloudtype.app"
    
    private init() {}
    
    func get<T: Decodable>(path: String = "", type: T.Type, handler: @escaping (T?) -> Void) {
        guard let url = URL(string: domain + path) else {
            print("HTTPRequest - get URL변환오류")
            handler(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, res, error in
            print(res.debugDescription)
            guard let data else {
                print("HTTPRequest - get data가 nil")
                handler(nil)
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(type, from: data)
                DispatchQueue.main.async {
                    handler(decodedData)
                }
            } catch {
                print("HTTPRequest - decoding 오류: \(error.localizedDescription)")
                handler(nil)
            }
        }.resume()
    }
    
    func post<T: Decodable, U: Encodable>(path: String = "", type: T.Type, body: U, handler: @escaping (T?) -> Void) {
        guard let url = URL(string: domain + path) else {
            print("HTTPRequest - post URL 변환 오류")
            handler(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let requestBody = try JSONEncoder().encode(body)
            request.httpBody = requestBody
        } catch {
            print("HTTPRequest - encoding 오류: \(error.localizedDescription)")
            handler(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("HTTPRequest - post data가 nil")
                handler(nil)
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(type, from: data)
                DispatchQueue.main.async {
                    handler(decodedData)
                }
            } catch {
                print("HTTPRequest - decoding 오류: \(error.localizedDescription)")
                handler(nil)
            }
        }.resume()
    }
}
