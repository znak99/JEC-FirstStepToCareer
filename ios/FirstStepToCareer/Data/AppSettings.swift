import Foundation

// 기기에 저장하는 앱 설정. 메뉴 화면에서 바꾼다
enum AppSettings {
  static let questionCountRange = 3...7
  static let defaultQuestionCount = 5
  private static let questionCountKey = "questionCount"
  private static let hasStartedKey = "hasStarted"

  // 시작 화면을 지나갔는지. 로그아웃·데이터 삭제 때 false로 돌려 시작 화면을 다시 보여 준다
  static func hasStarted(in defaults: UserDefaults = .standard) -> Bool {
    defaults.bool(forKey: hasStartedKey)
  }

  static func setHasStarted(_ value: Bool, in defaults: UserDefaults = .standard) {
    defaults.set(value, forKey: hasStartedKey)
  }

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
