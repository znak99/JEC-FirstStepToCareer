import Foundation

// 점수를 「78.4点」처럼 소수 한 자리 글자로 바꾼다. 점수가 없으면 「評価なし」. 분석·면접 결과 화면이 함께 쓴다
enum ScoreFormat {
  static func text(_ value: Double?) -> String {
    guard let value else { return String(localized: "評価なし") }
    return String(localized: "\(String(format: "%.1f", value))点")
  }
}
