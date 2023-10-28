//
//  CareerType.swift
//  JEC-FirstStepToCareer
//
//  Created by SeungWoo Hong on 2023/10/26.
//

import Foundation

enum CareerType: String, Identifiable, CaseIterable {
    
    var id: String {
        return self.rawValue
    }
    
    case sales = "営業"
    case office = "オフィスワーク"
    case shop = "販売"
    case food = "飲食・フード"
    case service = "サービス"
    case event = "レジャー・娯楽"
    case education = "教育"
    case sports = "スポーツ"
    case beauty = "美容"
    case medical = "医療・介護"
    case driver = "ドライバー・配達"
    case manufacturing = "製造・工場・倉庫"
    case engineer = "IT・エンジニア"
    case creator = "クリエイティブ・編集"
    case technical = "専門職・技術"
    case construction = "建設"
}
