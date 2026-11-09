import Foundation
import Testing

@testable import FirstStepToCareer

// 시작 화면과 메뉴의 계정 처리. StubURLProtocol을 함께 쓰므로 APIClientTests(.serialized) 안에서 돈다
extension APIClientTests {
  @MainActor @Test func startSignInSucceeds() async throws {
    StubURLProtocol.handler = { _ in (200, Data(#"{"accountType":"apple"}"#.utf8)) }
    let model = StartViewModel(signInWithApple: try useCases().signInWithApple)
    #expect(await model.signIn(AppleSignInRequest(identityToken: "t", nonce: "n")))
    #expect(!model.signInFailed)
    #expect(!model.isSigningIn)
  }

  @MainActor @Test func startSignInFailureStaysOnStartScreen() async throws {
    StubURLProtocol.handler = { _ in
      (401, Data(#"{"error":{"code":"UNAUTHORIZED","message":"bad"}}"#.utf8))
    }
    let model = StartViewModel(signInWithApple: try useCases().signInWithApple)
    #expect(await model.signIn(AppleSignInRequest(identityToken: "t", nonce: "n")) == false)
    #expect(model.signInFailed)
  }

  @MainActor @Test func menuDeleteFailureNamesTheAction() async throws {
    StubURLProtocol.handler = { _ in
      (500, Data(#"{"error":{"code":"INTERNAL","message":"x"}}"#.utf8))
    }
    let model = MenuViewModel(try useCases())
    #expect(await model.deleteAllData() == false)
    #expect(model.failure == .delete)
    #expect(model.working == nil)
  }

  @MainActor @Test func menuSignOutClearsWorkingWhenDone() async throws {
    StubURLProtocol.handler = { _ in (204, Data()) }
    let model = MenuViewModel(try useCases())
    #expect(await model.signOut())
    #expect(model.failure == nil)
    #expect(!model.isWorking)
  }
}
