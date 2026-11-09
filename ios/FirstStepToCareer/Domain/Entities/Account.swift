import CryptoKit
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

// Apple 로그인 때마다 새로 만드는 일회용 무작위 값. Apple에는 해시를, 서버에는 원문을 보낸다
enum SignInNonce {
  private static let characters = Array(
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")

  static func make(length: Int = 32) -> String {
    var generator = SystemRandomNumberGenerator()
    return String((0..<length).map { _ in characters.randomElement(using: &generator)! })
  }

  static func sha256Hex(_ value: String) -> String {
    SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
  }
}
