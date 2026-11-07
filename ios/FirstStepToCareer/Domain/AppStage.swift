import Foundation

// 앱을 켰을 때 보여 줄 화면 단계 (SITE_MAP 2절)
enum AppStage: Equatable, Sendable {
  case consent, start, profile, tabs

  // - 지금 버전의 약관에 동의하지 않았으면 먼저 동의를 받는다(처음, 약관 버전 변경, 예전부터 쓰던 사용자)
  // - 처음 쓰는 사용자는 시작(로그인 방식 고르기)을 거쳐 정보 입력으로 간다. 시작을 고른 뒤 앱이 꺼졌으면 정보 입력부터 이어 한다
  // - 이미 시작한 사용자라도 이 iPhone에 프로필이 없으면 정보 입력을 한 번 거친다(온보딩 전부터 쓰던 사용자)
  static func of(hasAgreed: Bool, hasStarted: Bool, choseStart: Bool, hasProfile: Bool) -> AppStage
  {
    if !hasAgreed { return .consent }
    if hasStarted { return hasProfile ? .tabs : .profile }
    return choseStart ? .profile : .start
  }
}
