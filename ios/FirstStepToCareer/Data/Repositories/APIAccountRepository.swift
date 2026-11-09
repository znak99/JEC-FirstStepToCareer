import Foundation

// AccountRepository를 서버 API로 채운다. 로그아웃·삭제에 성공하면 APIClient가 기기 토큰을 바꾼다
struct APIAccountRepository: AccountRepository {
  let api: APIClient

  func status() async throws -> AccountStatus {
    try await api.me()
  }

  func signInWithApple(_ request: AppleSignInRequest) async throws -> AccountStatus {
    try await api.signInWithApple(request)
  }

  func signOut() async throws {
    try await api.signOut()
  }

  func deleteAllData() async throws {
    try await api.deleteAllData()
  }
}
