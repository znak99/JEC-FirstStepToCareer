import Foundation

// 계정 API가 주고받는 JSON 그대로의 형식 (ARCHITECTURE.md 5절 계정 API 상세)
extension AccountType: Codable {}

struct AccountStatusDTO: Codable, Equatable {
  let accountType: AccountType

  var domain: AccountStatus { AccountStatus(accountType: accountType) }
}

struct AppleSignInRequestDTO: Codable, Equatable {
  let identityToken: String
  let nonce: String

  init(_ value: AppleSignInRequest) {
    identityToken = value.identityToken
    nonce = value.nonce
  }
}
