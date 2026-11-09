import Foundation

// 기기에 저장하는 앱 설정. 메뉴 화면에서 바꾼다
enum AppSettings {
  static let questionCountRange = InterviewDraft.questionCountRange
  static let defaultQuestionCount = InterviewDraft.defaultQuestionCount
  private static let questionCountKey = "questionCount"
  private static let hasStartedKey = "hasStarted"
  private static let agreedVersionsKey = "agreedDocumentVersions"
  private static let hasChosenStartKey = "hasChosenStart"

  // 온보딩(동의 → 시작 → 정보 입력)을 마쳤는지. 로그아웃·데이터 삭제 때 false로 돌려 온보딩을 다시 보여 준다
  static func hasStarted(in defaults: UserDefaults = .standard) -> Bool {
    defaults.bool(forKey: hasStartedKey)
  }

  static func setHasStarted(_ value: Bool, in defaults: UserDefaults = .standard) {
    defaults.set(value, forKey: hasStartedKey)
  }

  // 이용약관·개인정보 처리방침의 지금 버전에 모두 동의했는지
  static func hasAgreed(in defaults: UserDefaults = .standard) -> Bool {
    let agreed = defaults.dictionary(forKey: agreedVersionsKey) as? [String: String] ?? [:]
    return LegalDocument.allCases.allSatisfy { agreed[$0.rawValue] == $0.version }
  }

  static func saveAgreement(in defaults: UserDefaults = .standard) {
    let versions = Dictionary(
      uniqueKeysWithValues: LegalDocument.allCases.map { ($0.rawValue, $0.version) })
    defaults.set(versions, forKey: agreedVersionsKey)
  }

  static func clearAgreement(in defaults: UserDefaults = .standard) {
    defaults.removeObject(forKey: agreedVersionsKey)
  }

  // 예전 버전에 동의한 적이 있는지. 약관이 바뀌어 다시 동의를 받을 때 안내 문구를 바꾼다
  static func hasOutdatedAgreement(in defaults: UserDefaults = .standard) -> Bool {
    let agreed = defaults.dictionary(forKey: agreedVersionsKey) as? [String: String] ?? [:]
    return !agreed.isEmpty && !hasAgreed(in: defaults)
  }

  // 온보딩에서 시작(로그인 방식)을 골랐는지. 정보 입력 도중 앱이 꺼지면 다음에 정보 입력부터 이어 한다
  static func hasChosenStart(in defaults: UserDefaults = .standard) -> Bool {
    defaults.bool(forKey: hasChosenStartKey)
  }

  static func setHasChosenStart(_ value: Bool, in defaults: UserDefaults = .standard) {
    defaults.set(value, forKey: hasChosenStartKey)
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
