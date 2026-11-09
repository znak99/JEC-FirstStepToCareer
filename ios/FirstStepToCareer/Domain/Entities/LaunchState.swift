import Foundation

// 앱을 켤 때 이 iPhone에 남아 있는 온보딩 진행 상태. 어느 화면부터 보여 줄지는 AppStage가 정한다
struct LaunchState: Equatable, Sendable {
  var hasAgreed: Bool
  var hasStarted: Bool
  var hasChosenStart: Bool
  var hasProfile: Bool
  // 예전 버전의 약관에만 동의했는지. 동의 화면의 안내 문구를 바꾼다
  var hasOutdatedAgreement: Bool

  var stage: AppStage {
    AppStage.of(
      hasAgreed: hasAgreed, hasStarted: hasStarted, choseStart: hasChosenStart,
      hasProfile: hasProfile)
  }

  // 약관 버전이 바뀌어 탭 화면 위에서 동의만 다시 받아야 하는지
  var asksAgreementOverTabs: Bool {
    AppStage.asksAgreementOverTabs(
      hasAgreed: hasAgreed, hasStarted: hasStarted, hasProfile: hasProfile)
  }
}

// Apple 로그인 한 번에 쓰는 일회용 값. Apple에는 해시를, 서버에는 원문을 보낸다
struct SignInChallenge: Equatable, Sendable {
  let nonce: String
  let hashedNonce: String
}
