import Foundation
import Testing

@testable import FirstStepToCareer

struct DeviceTokenTests {
  @Test func tokenIsBase64URLWith43Characters() {
    let token = DeviceTokenStore.makeToken()
    #expect(token.count == 43)
    #expect(token.allSatisfy { $0.isLetter && $0.isASCII || $0.isNumber || $0 == "-" || $0 == "_" })
  }

  @Test func storeKeepsAndReplacesToken() throws {
    let store = DeviceTokenStore(service: "test.\(UUID().uuidString)")
    let first = try store.currentToken()
    #expect(try store.currentToken() == first)
    let replaced = try store.replaceToken()
    #expect(replaced != first)
  }
}

struct SignInNonceTests {
  @Test func makesRandomNonceWithinServerLimits() {
    let nonce = SignInNonce.make()
    #expect((16...128).contains(nonce.count))
    #expect(nonce != SignInNonce.make())
  }

  @Test func hashesWithSHA256Hex() {
    #expect(
      SignInNonce.sha256Hex("abc")
        == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
  }
}
