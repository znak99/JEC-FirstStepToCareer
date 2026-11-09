import SwiftUI

// 앱 전체가 쓰는 색. 기기의 밝은/어두운 모드를 따르되 남색 바탕과 형광색 선으로 맞춘다
enum TechPalette {
  // 어두운 모드는 앱 아이콘의 밝은 파랑을 쓴다
  static let accent = adaptive(light: 0x0A7CD8, dark: 0x2392FF)
  static let accentSoft = adaptive(light: 0x6C5CE7, dark: 0x4D7CFF)
  static let positive = adaptive(light: 0x009E7A, dark: 0x2EF2B5)
  static let negative = adaptive(light: 0xE0445F, dark: 0xFF6B8A)
  static let cardTop = adaptive(light: 0xFFFFFF, dark: 0x10213F)
  static let cardBottom = adaptive(light: 0xE9F1FF, dark: 0x070F22)
  // 시작·온보딩 화면 전체에 까는 바탕. 어두운 모드는 다른 화면처럼 검은색에 가깝게 한다
  static let pageTop = adaptive(light: 0xFFFFFF, dark: 0x0A0E17)
  static let pageBottom = adaptive(light: 0xE9F1FF, dark: 0x000000)
  // 눈금·격자용. 투명도를 낮춰 쓴다
  static let ink = adaptive(light: 0x0B2A55, dark: 0xFFFFFF)

  static var areaFill: LinearGradient {
    LinearGradient(
      colors: [accent.opacity(0.35), accent.opacity(0)], startPoint: .top, endPoint: .bottom)
  }

  static var barFill: LinearGradient {
    LinearGradient(colors: [accentSoft, accent], startPoint: .leading, endPoint: .trailing)
  }

  private static func adaptive(light: UInt32, dark: UInt32) -> Color {
    Color(
      UIColor { traits in
        let hex = traits.userInterfaceStyle == .dark ? dark : light
        return UIColor(
          red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
          blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
      })
  }
}

// 앱 아이콘과 같은 파란 그라데이션. 밝은/어두운 모드와 관계없이 같다
enum BrandPalette {
  static let top = Color(red: 0x23 / 255, green: 0x92 / 255, blue: 0xFF / 255)
  // 실행 화면 색(Assets의 LaunchBackground)과 같아야 한다
  static let middle = Color(red: 0x17 / 255, green: 0x6D / 255, blue: 0xDC / 255)
  static let bottom = Color(red: 0x07 / 255, green: 0x45 / 255, blue: 0xB6 / 255)
  static let glow = Color(red: 0.55, green: 0.9, blue: 1)
}
