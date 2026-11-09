import Foundation
import Security

// 기기 토큰은 무작위 32바이트를 패딩 없는 base64url로 만든 43자 문자열이다
struct DeviceTokenStore: Sendable {
  let service: String

  init(service: String = "cloud.znak99.FirstStepToCareer.deviceToken") {
    self.service = service
  }

  func currentToken() throws -> String {
    if let existing = try read() { return existing }
    let token = Self.makeToken()
    try save(token)
    return token
  }

  func replaceToken() throws -> String {
    try delete()
    return try currentToken()
  }

  static func makeToken() -> String {
    var bytes = [UInt8](repeating: 0, count: 32)
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    precondition(status == errSecSuccess, "Secure random generation failed")
    return Data(bytes).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  private var baseQuery: [String: Any] {
    [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service]
  }

  private func read() throws -> String? {
    var query = baseQuery
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess, let data = item as? Data else {
      throw KeychainError(status: status)
    }
    return String(data: data, encoding: .utf8)
  }

  private func save(_ token: String) throws {
    var query = baseQuery
    query[kSecValueData as String] = Data(token.utf8)
    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else { throw KeychainError(status: status) }
  }

  private func delete() throws {
    let status = SecItemDelete(baseQuery as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError(status: status)
    }
  }
}

struct KeychainError: Error {
  let status: OSStatus
}
