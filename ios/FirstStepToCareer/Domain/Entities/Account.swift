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
