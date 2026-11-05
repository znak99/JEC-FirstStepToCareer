import Foundation

// 기기에 저장하는 앱 설정. 메뉴 화면에서 바꾼다
enum AppSettings {
  static let questionCountRange = 3...7
  static let defaultQuestionCount = 5
  private static let questionCountKey = "questionCount"

  static func questionCount(in defaults: UserDefaults = .standard) -> Int {
    let stored = defaults.integer(forKey: questionCountKey)
    return questionCountRange.contains(stored) ? stored : defaultQuestionCount
  }

  static func setQuestionCount(_ value: Int, in defaults: UserDefaults = .standard) {
    defaults.set(
      min(max(value, questionCountRange.lowerBound), questionCountRange.upperBound),
      forKey: questionCountKey)
  }
}
