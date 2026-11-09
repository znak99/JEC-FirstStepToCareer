import Foundation

// 계정(게스트·Apple)과 로그인 상태
protocol AccountRepository: Sendable {
  func status() async throws -> AccountStatus
  func signInWithApple(_ request: AppleSignInRequest) async throws -> AccountStatus
  // 성공하면 이 iPhone은 새 게스트로 다시 시작한다
  func signOut() async throws
  // 계정과 모든 기록을 지운다. 성공하면 이 iPhone은 새 게스트로 다시 시작한다
  func deleteAllData() async throws
}
