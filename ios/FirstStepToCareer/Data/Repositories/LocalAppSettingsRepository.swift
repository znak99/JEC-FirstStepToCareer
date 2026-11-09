import Foundation

// AppSettingsRepository를 이 iPhone의 UserDefaults로 채운다
// UserDefaults는 여러 스레드에서 써도 안전하다고 Apple 문서에 적혀 있다
struct LocalAppSettingsRepository: AppSettingsRepository, @unchecked Sendable {
  let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  var questionCount: Int { AppSettings.questionCount(in: defaults) }
  func setQuestionCount(_ value: Int) { AppSettings.setQuestionCount(value, in: defaults) }
  var hasStarted: Bool { AppSettings.hasStarted(in: defaults) }
  func setHasStarted(_ value: Bool) { AppSettings.setHasStarted(value, in: defaults) }
  var hasChosenStart: Bool { AppSettings.hasChosenStart(in: defaults) }
  func setHasChosenStart(_ value: Bool) { AppSettings.setHasChosenStart(value, in: defaults) }
  var hasAgreed: Bool { AppSettings.hasAgreed(in: defaults) }
  var hasOutdatedAgreement: Bool { AppSettings.hasOutdatedAgreement(in: defaults) }
  func saveAgreement() { AppSettings.saveAgreement(in: defaults) }
  func clearAgreement() { AppSettings.clearAgreement(in: defaults) }
}
