import Foundation

// 계정과 Apple 로그인 (ARCHITECTURE.md 6.3)

// Apple 로그인 버튼을 누를 때마다 새 일회용 값을 만든다
struct MakeSignInChallengeUseCase: Sendable {
  let nonces: any SignInNonceGenerating

  func execute() -> SignInChallenge {
    let nonce = nonces.make()
    return SignInChallenge(nonce: nonce, hashedNonce: nonces.sha256Hex(nonce))
  }
}

struct SignInWithAppleUseCase: Sendable {
  let accounts: any AccountRepository

  func execute(_ request: AppleSignInRequest) async throws -> AccountType {
    try await accounts.signInWithApple(request).accountType
  }
}

struct GetAccountTypeUseCase: Sendable {
  let accounts: any AccountRepository

  func execute() async throws -> AccountType {
    try await accounts.status().accountType
  }
}

// 성공하면 이 iPhone은 새 게스트로 다시 시작한다. 이 iPhone의 값은 ResetLocalDataUseCase가 지운다
struct SignOutUseCase: Sendable {
  let accounts: any AccountRepository

  func execute() async throws { try await accounts.signOut() }
}

// 계정과 모든 기록을 지운다. 이 iPhone의 값은 ResetLocalDataUseCase가 지운다
struct DeleteAllDataUseCase: Sendable {
  let accounts: any AccountRepository

  func execute() async throws { try await accounts.deleteAllData() }
}
