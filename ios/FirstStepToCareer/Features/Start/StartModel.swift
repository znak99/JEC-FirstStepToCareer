import Foundation
import Observation

@MainActor
@Observable
final class StartModel {
  private(set) var isSigningIn = false
  var signInFailed = false

  private let api: APIClient

  init(api: APIClient) {
    self.api = api
  }

  // 성공하면 true. 실패하면 안내를 띄우고 시작 화면에 남는다
  func signIn(_ request: AppleSignInRequest) async -> Bool {
    guard !isSigningIn else { return false }
    isSigningIn = true
    defer { isSigningIn = false }
    do {
      _ = try await api.signInWithApple(request)
      return true
    } catch {
      signInFailed = true
      return false
    }
  }

  func reportSignInFailure() {
    signInFailed = true
  }
}
