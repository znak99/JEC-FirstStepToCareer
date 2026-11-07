import Foundation
import Testing

@testable import FirstStepToCareer

// StubURLProtocol을 함께 쓰므로 APIClientTests(.serialized) 안에서 돈다
extension APIClientTests {
  private func routed(
    _ routes: @escaping (String, String) -> (Int, String)
  ) -> (Recorder, Recorder) {
    let requests = Recorder()
    let bodies = Recorder()
    StubURLProtocol.handler = { request in
      let method = request.httpMethod ?? ""
      let path = request.url?.path ?? ""
      requests.append("\(method) \(path)")
      bodies.append(StubURLProtocol.lastBody.flatMap { String(data: $0, encoding: .utf8) } ?? "")
      let (status, body) = routes(method, path)
      return (status, Data(body.utf8))
    }
    return (requests, bodies)
  }

  private func json(_ text: String) throws -> [String: Any] {
    try #require(try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
  }

  @Test func decodesMissingProfileAsNil() async throws {
    let (requests, _) = routed { _, _ in (200, #"{"profile":null}"#) }
    #expect(try await client.profile() == nil)
    #expect(requests.items == ["GET /v1/me/profile"])
  }

  @Test func savesProfileAndLeavesOutEmptyFields() async throws {
    let (requests, bodies) = routed { _, _ in
      (
        200,
        #"{"profile":{"nickname":"たろう","hiringType":"new_grad","industry":null,"jobTitle":null}}"#
      )
    }
    let profile = try #require(
      Profile(nickname: "たろう", hiringType: .newGrad, industry: "", jobTitle: ""))
    let saved = try await client.saveProfile(profile)
    #expect(saved == profile)
    #expect(requests.items == ["PUT /v1/me/profile"])
    let body = try json(try #require(bodies.items.first))
    #expect(body["nickname"] as? String == "たろう")
    #expect(body["hiringType"] as? String == "new_grad")
    #expect(body["industry"] == nil)
  }

  @Test func recordsConsentsWithCurrentVersions() async throws {
    let (requests, bodies) = routed { _, _ in (204, "") }
    try await client.recordConsents(LegalDocument.allCases)
    #expect(requests.items == ["POST /v1/me/consents"])
    let sent = try #require(bodies.items.first)
    let consents = try #require(try json(sent)["consents"] as? [[String: String]])
    #expect(
      consents == LegalDocument.allCases.map { ["document": $0.rawValue, "version": $0.version] })
  }

  @MainActor @Test func onboardingSaveRecordsConsentsThenProfile() async throws {
    let (requests, _) = routed { method, _ in
      method == "PUT"
        ? (
          200, #"{"profile":{"nickname":"たろう","hiringType":null,"industry":null,"jobTitle":null}}"#
        )
        : (204, "")
    }
    let store = ProfileStore(
      defaults: try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)")))
    let model = ProfileModel(api: client, store: store)
    let profile = try #require(
      Profile(nickname: "たろう", hiringType: nil, industry: "", jobTitle: ""))

    #expect(await model.save(profile, agreeingTo: LegalDocument.allCases))
    #expect(requests.items == ["POST /v1/me/consents", "PUT /v1/me/profile"])
    #expect(store.profile == profile)
    #expect(!model.saveFailed)
  }

  @MainActor @Test func failedSaveKeepsStoreAndReportsFailure() async throws {
    let (requests, _) = routed { method, _ in
      method == "PUT" ? (500, #"{"error":{"code":"INTERNAL_ERROR","message":"x"}}"#) : (204, "")
    }
    let store = ProfileStore(
      defaults: try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)")))
    let model = ProfileModel(api: client, store: store)
    let profile = try #require(
      Profile(nickname: "たろう", hiringType: nil, industry: "", jobTitle: ""))

    #expect(await model.save(profile) == false)
    #expect(requests.items == ["PUT /v1/me/profile"])
    #expect(model.saveFailed)
    #expect(store.profile == nil)
  }

  @MainActor @Test func agreeingAgainRecordsOnlyConsents() async throws {
    let (requests, _) = routed { _, _ in (204, "") }
    let model = ProfileModel(api: client)
    #expect(await model.agree(to: LegalDocument.allCases))
    #expect(requests.items == ["POST /v1/me/consents"])
    #expect(!model.saveFailed)
  }

  @MainActor @Test func failedAgreementReportsFailure() async throws {
    _ = routed { _, _ in (0, "") }
    let model = ProfileModel(api: client)
    #expect(await model.agree(to: LegalDocument.allCases) == false)
    #expect(model.saveFailed)
    #expect(!model.isSaving)
  }

  @MainActor @Test func loadKeepsServerProfileAndFallsBackToStore() async throws {
    let store = ProfileStore(
      defaults: try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)")))
    let model = ProfileModel(api: client, store: store)

    _ = routed { _, _ in
      (
        200,
        #"{"profile":{"nickname":"はなこ","hiringType":"mid_career","industry":"広告","jobTitle":null}}"#
      )
    }
    let loaded = try #require(await model.load())
    #expect(loaded.nickname == "はなこ")
    #expect(store.profile == loaded)

    // 통신에 실패하면 이 iPhone에 남은 값을 쓴다
    _ = routed { _, _ in (500, "") }
    #expect(await model.load() == loaded)
  }
}
