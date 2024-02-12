//
//  CompanyType.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/19.
//

import Foundation

enum CompanyType: String, Identifiable, CaseIterable {
    
    var id: String {
        return self.rawValue
    }
    
    case maker = "メーカー"
    case trading = "商社"
    case retail = "小売"
    case finance = "金融"
    case service = "サービス"
    case software = "ソフトウェア・通信"
    case massmedia = "マスコミ"
    case government = "官公庁・公社・団体"
    case none = "分野を選択してください"
}
