import Foundation

// 이 iPhone에만 두는 앱 설정과 온보딩 진행 상태
protocol AppSettingsRepository: Sendable {
  // 마지막으로 고른 질문 수. 범위를 벗어난 값은 기본값으로 읽고, 저장할 때는 범위 안으로 맞춘다
  var questionCount: Int { get }
  func setQuestionCount(_ value: Int)
  // 온보딩(동의 → 시작 → 정보 입력)을 마쳤는지
  var hasStarted: Bool { get }
  func setHasStarted(_ value: Bool)
  // 온보딩에서 시작(로그인 방식)을 골랐는지
  var hasChosenStart: Bool { get }
  func setHasChosenStart(_ value: Bool)
  // 지금 버전의 약관에 모두 동의했는지
  var hasAgreed: Bool { get }
  // 예전 버전에만 동의한 적이 있는지
  var hasOutdatedAgreement: Bool { get }
  func saveAgreement()
  func clearAgreement()
}
