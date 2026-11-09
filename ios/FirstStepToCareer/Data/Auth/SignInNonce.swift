import CryptoKit
import Foundation

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

// SignInNonceGenerating을 이 iPhone의 난수와 SHA-256으로 채운다
struct SystemSignInNonce: SignInNonceGenerating {
  func make() -> String { SignInNonce.make() }
  func sha256Hex(_ value: String) -> String { SignInNonce.sha256Hex(value) }
}
