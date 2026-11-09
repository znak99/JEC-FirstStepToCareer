import Foundation

enum AccountType: String, Sendable {
  case guest
  case apple
}

struct AccountStatus: Sendable {
  let accountType: AccountType
}

struct AppleSignInRequest: Sendable {
  let identityToken: String
  let nonce: String
}

// Apple 로그인 한 번에 쓰는 일회용 값. Apple에는 해시를, 서버에는 원문을 보낸다
struct SignInChallenge: Equatable, Sendable {
  let nonce: String
  let hashedNonce: String
}
