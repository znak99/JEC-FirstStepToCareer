import Foundation

// 빌드할 때 정해지는 앱 정보
struct AppInfo: Equatable, Sendable {
  // 「0.1.0 (1)」처럼 버전과 빌드 번호
  var version: String
  // 무료 Apple 계정 빌드에서는 Apple 로그인을 쓸 수 없어 기본은 꺼짐이다
  var appleSignInEnabled: Bool
}
