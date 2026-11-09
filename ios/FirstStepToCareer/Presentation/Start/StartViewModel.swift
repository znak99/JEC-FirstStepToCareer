import Foundation
import Observation

@MainActor
@Observable
final class StartViewModel {
  private(set) var isSigningIn = false
  var signInFailed = false

  private let signInWithApple: SignInWithAppleUseCase

  init(signInWithApple: SignInWithAppleUseCase) {
    self.signInWithApple = signInWithApple
  }

  // 성공하면 true. 실패하면 안내를 띄우고 시작 화면에 남는다
  func signIn(_ request: AppleSignInRequest) async -> Bool {
    guard !isSigningIn else { return false }
    isSigningIn = true
    defer { isSigningIn = false }
    do {
      _ = try await signInWithApple.execute(request)
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
