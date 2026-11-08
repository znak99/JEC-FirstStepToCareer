import Foundation
import Testing

@testable import FirstStepToCareer

final class StubURLProtocol: URLProtocol {
  nonisolated(unsafe) static var handler: ((URLRequest) -> (Int, Data))?
  nonisolated(unsafe) static var lastRequest: URLRequest?
  nonisolated(unsafe) static var lastBody: Data?

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    Self.lastRequest = request
    Self.lastBody =
      request.httpBody
      ?? request.httpBodyStream.map { stream in
        stream.open()
        defer { stream.close() }
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
          let read = stream.read(buffer, maxLength: 1024)
          if read <= 0 { break }
          data.append(buffer, count: read)
        }
        return data
      }
    let (status, body) = Self.handler?(request) ?? (500, Data())
    let response = HTTPURLResponse(
      url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: body)
    client?.urlProtocolDidFinishLoading(self)
  }
  override func stopLoading() {}
}

// 스텁 서버가 받은 요청을 순서대로 모은다. 요청은 다른 스레드에서 오므로 잠근다
final class Recorder: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [String] = []

  var items: [String] { lock.withLock { storage } }
  func append(_ item: String) { lock.withLock { storage.append(item) } }
}

@Suite(.serialized)
struct APIClientTests {
  let client: APIClient

  init() {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    client = APIClient(
      baseURL: URL(string: "https://example.com")!,
      tokenStore: DeviceTokenStore(service: "test.\(UUID().uuidString)"),
      session: URLSession(configuration: configuration))
  }

  @Test func sendsDeviceTokenAndDecodesStatus() async throws {
    StubURLProtocol.handler = { _ in (200, Data(#"{"aiEnabled":true}"#.utf8)) }
    let status = try await client.status()
    #expect(status.aiEnabled)
    let header = StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization") ?? ""
    #expect(header.hasPrefix("Bearer "))
    #expect(header.count == "Bearer ".count + 43)
  }

  @Test func mapsServerErrorCode() async {
    StubURLProtocol.handler = { _ in
      (503, Data(#"{"error":{"code":"AI_DISABLED","message":"off"}}"#.utf8))
    }
    await #expect(throws: APIError.server(status: 503, code: "AI_DISABLED")) {
      try await client.status()
    }
  }

  @Test func decodesAnswerResultWithNextQuestion() async throws {
    StubURLProtocol.handler = { _ in
      (
        200,
        Data(
          #"{"status":"in_progress","nextQuestion":{"id":"q2","position":2,"preface":"なるほど","text":"次の質問","answer":null,"scores":null},"closingMessage":null}"#
            .utf8)
      )
    }
    let result = try await client.submitAnswer(
      interviewId: "i", questionId: "q1",
      AnswerSubmission(transcript: "はい", durationMs: 10, gaze: nil, head: nil))
    #expect(result.nextQuestion?.position == 2)
    #expect(result.status == .inProgress)
    let body = try #require(StubURLProtocol.lastBody)
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(json.keys.contains("gaze"))
    #expect(json["gaze"] is NSNull)
  }

  @Test func decodesCompletedInterviewDetail() async throws {
    let json = #"""
      {"id":"i","companyName":"A","industry":"IT","jobTitle":"SE","interviewType":"hr","hiringType":"new_grad","questionCount":3,"faceTracking":false,"status":"completed","startedAt":"2026-11-06T00:00:00.000Z","completedAt":"2026-11-06T00:10:00.000Z","scores":{"total":75,"structure":80,"logic":70,"gaze":null,"head":null},"feedback":"良い","closingMessage":"ありがとうございました","questions":[{"id":"q1","position":1,"preface":"本日は","text":"自己紹介を","answer":{"transcript":"はい","durationMs":1000,"gaze":null,"head":null},"scores":{"structure":80,"logic":70,"gaze":null,"head":null}}]}
      """#
    StubURLProtocol.handler = { _ in (200, Data(json.utf8)) }
    let detail = try await client.interview(id: "i")
    #expect(detail.status == .completed)
    #expect(detail.scores?.total == 75)
    #expect(detail.questions.first?.scores?.gaze == nil)
  }

  @Test func decodesAccountStatus() async throws {
    StubURLProtocol.handler = { _ in (200, Data(#"{"accountType":"guest"}"#.utf8)) }
    #expect(try await client.me().accountType == .guest)
    #expect(StubURLProtocol.lastRequest?.url?.path == "/v1/me")
  }

  @Test func sendsAppleIdentityTokenAndRawNonce() async throws {
    StubURLProtocol.handler = { _ in (200, Data(#"{"accountType":"apple"}"#.utf8)) }
    let status = try await client.signInWithApple(
      AppleSignInRequest(identityToken: "token", nonce: "raw-nonce-1234567890"))
    #expect(status.accountType == .apple)
    let body = try #require(StubURLProtocol.lastBody)
    let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: String])
    #expect(json == ["identityToken": "token", "nonce": "raw-nonce-1234567890"])
  }

  @Test func signOutAndDeleteReplaceDeviceToken() async throws {
    StubURLProtocol.handler = { _ in (204, Data()) }
    let first = try client.tokenStore.currentToken()
    try await client.signOut()
    #expect(StubURLProtocol.lastRequest?.httpMethod == "POST")
    #expect(
      StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer \(first)")
    let second = try client.tokenStore.currentToken()
    #expect(second != first)
    try await client.deleteAllData()
    #expect(StubURLProtocol.lastRequest?.httpMethod == "DELETE")
    #expect(try client.tokenStore.currentToken() != second)
  }

  @Test func keepsDeviceTokenWhenSignOutFails() async throws {
    StubURLProtocol.handler = { _ in
      (409, Data(#"{"error":{"code":"INVALID_STATE","message":"guest"}}"#.utf8))
    }
    let first = try client.tokenStore.currentToken()
    await #expect(throws: APIError.server(status: 409, code: "INVALID_STATE")) {
      try await client.signOut()
    }
    #expect(try client.tokenStore.currentToken() == first)
  }

  @MainActor @Test func startSignInSucceeds() async {
    StubURLProtocol.handler = { _ in (200, Data(#"{"accountType":"apple"}"#.utf8)) }
    let model = StartModel(api: client)
    #expect(await model.signIn(AppleSignInRequest(identityToken: "t", nonce: "n")))
    #expect(!model.signInFailed)
    #expect(!model.isSigningIn)
  }

  @MainActor @Test func startSignInFailureStaysOnStartScreen() async {
    StubURLProtocol.handler = { _ in
      (401, Data(#"{"error":{"code":"UNAUTHORIZED","message":"bad"}}"#.utf8))
    }
    let model = StartModel(api: client)
    #expect(await model.signIn(AppleSignInRequest(identityToken: "t", nonce: "n")) == false)
    #expect(model.signInFailed)
  }

  @MainActor @Test func menuDeleteFailureNamesTheAction() async {
    StubURLProtocol.handler = { _ in
      (500, Data(#"{"error":{"code":"INTERNAL","message":"x"}}"#.utf8))
    }
    let model = MenuModel(api: client)
    #expect(await model.deleteAllData() == false)
    #expect(model.failure == .delete)
    #expect(model.working == nil)
  }

  @MainActor @Test func menuSignOutClearsWorkingWhenDone() async {
    StubURLProtocol.handler = { _ in (204, Data()) }
    let model = MenuModel(api: client)
    #expect(await model.signOut())
    #expect(model.failure == nil)
    #expect(!model.isWorking)
  }

  // 남은 면접 정리 테스트용. 요청을 "메서드 경로"로 기록하고 경로별로 응답한다
  private func cleaner(
    storedId: String?, routes: @escaping (String, String) -> (Int, String)
  ) throws -> (LeftoverInterviewCleaner, ActiveInterviewStore, Recorder) {
    let defaults = try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)"))
    let store = ActiveInterviewStore(defaults: defaults)
    if let storedId { store.save(storedId) }
    let recorder = Recorder()
    StubURLProtocol.handler = { request in
      let method = request.httpMethod ?? ""
      // cursor가 붙은 요청을 구분할 수 있게 쿼리도 포함한다
      let path = (request.url?.path ?? "") + (request.url?.query.map { "?\($0)" } ?? "")
      recorder.append("\(method) \(path)")
      let (status, body) = routes(method, path)
      return (status, Data(body.utf8))
    }
    return (LeftoverInterviewCleaner(api: client, store: store), store, recorder)
  }

  private static func detail(status: String) -> String {
    #"{"id":"i1","companyName":"A","industry":"IT","jobTitle":"SE","interviewType":"hr","hiringType":"new_grad","questionCount":3,"faceTracking":false,"status":""#
      + status
      + #"","startedAt":"2026-11-06T00:00:00.000Z","completedAt":null,"scores":null,"feedback":null,"closingMessage":null,"questions":[]}"#
  }

  private static func summary(id: String, status: String) -> String {
    #"{"id":""# + id
      + #"","companyName":"A","industry":"IT","jobTitle":"SE","interviewType":"hr","hiringType":"new_grad","status":""#
      + status + #"","startedAt":"2026-11-06T00:00:00.000Z","completedAt":null,"scores":null}"#
  }

  @Test func deletesUnfinishedInterviewStartedOnThisDevice() async throws {
    let (cleaner, store, recorder) = try cleaner(storedId: "i1") { method, _ in
      method == "DELETE" ? (204, "") : (200, Self.detail(status: "in_progress"))
    }
    await cleaner.deleteUnfinished()
    #expect(recorder.items == ["GET /v1/interviews/i1", "DELETE /v1/interviews/i1"])
    #expect(store.interviewId == nil)
  }

  @Test func keepsAwaitingInterviewInsteadOfDeleting() async throws {
    let (cleaner, store, recorder) = try cleaner(storedId: "i1") { _, _ in
      (200, Self.detail(status: "awaiting_evaluation"))
    }
    await cleaner.deleteUnfinished()
    #expect(recorder.items == ["GET /v1/interviews/i1"])
    #expect(store.interviewId == nil)
  }

  @Test func forgetsInterviewThatNoLongerExists() async throws {
    let (cleaner, store, _) = try cleaner(storedId: "i1") { _, _ in
      (404, #"{"error":{"code":"NOT_FOUND","message":"none"}}"#)
    }
    await cleaner.deleteUnfinished()
    #expect(store.interviewId == nil)
  }

  @Test func keepsInterviewIdWhenDeleteFails() async throws {
    let (cleaner, store, _) = try cleaner(storedId: "i1") { method, _ in
      method == "DELETE"
        ? (500, #"{"error":{"code":"INTERNAL","message":"x"}}"#)
        : (200, Self.detail(status: "in_progress"))
    }
    await cleaner.deleteUnfinished()
    #expect(store.interviewId == "i1")
  }

  @Test func doesNothingWithoutStoredInterview() async throws {
    let (cleaner, _, recorder) = try cleaner(storedId: nil) { _, _ in (500, "") }
    await cleaner.deleteUnfinished()
    #expect(recorder.items.isEmpty)
  }

  @Test func evaluatesOnlyAwaitingInterviewsAcrossPages() async throws {
    let (cleaner, _, recorder) = try cleaner(storedId: nil) { method, path in
      switch (method, path) {
      case ("GET", "/v1/status"): return (200, #"{"aiEnabled":true}"#)
      case ("GET", "/v1/interviews"):
        return (
          200,
          #"{"items":["# + Self.summary(id: "a", status: "awaiting_evaluation") + ","
            + Self.summary(id: "b", status: "completed") + #"],"nextCursor":"c1"}"#
        )
      case ("GET", "/v1/interviews?cursor=c1"):
        return (
          200,
          #"{"items":["# + Self.summary(id: "c", status: "awaiting_evaluation") + ","
            + Self.summary(id: "d", status: "in_progress") + #"],"nextCursor":null}"#
        )
      default: return (200, Self.detail(status: "completed"))
      }
    }
    await cleaner.evaluatePending()
    #expect(
      recorder.items.filter { $0.hasPrefix("POST") } == [
        "POST /v1/interviews/a/evaluation", "POST /v1/interviews/c/evaluation",
      ])
  }

  @Test func skipsEvaluationWhenAIIsOff() async throws {
    let (cleaner, _, recorder) = try cleaner(storedId: nil) { _, _ in
      (200, #"{"aiEnabled":false}"#)
    }
    await cleaner.evaluatePending()
    #expect(recorder.items == ["GET /v1/status"])
  }

  // 스플래시 테스트용. 애니메이션 시간을 줄여 빠르게 확인한다
  @MainActor
  private func splash(
    storedId: String? = nil, hasStarted: Bool = false, animation: Duration = .milliseconds(300),
    limit: Duration = .seconds(2), extraDelay: Duration = .zero,
    routes: @escaping (String, String) -> (Int, String) = { _, _ in (200, #"{"aiEnabled":true}"#) }
  ) throws -> (SplashModel, ActiveInterviewStore, Recorder) {
    let (_, store, recorder) = try cleaner(storedId: storedId, routes: routes)
    let model = SplashModel(
      api: client, hasStarted: hasStarted, store: store,
      timing: SplashModel.Timing(animation: animation, loadingLimit: limit), extraDelay: extraDelay)
    return (model, store, recorder)
  }

  @MainActor @Test func splashMovesOnRightAfterAnimationWhenReady() async throws {
    let (model, _, recorder) = try splash()
    await model.run()
    #expect(model.isFinished)
    #expect(!model.showsLoading)
    #expect(recorder.items == ["GET /v1/status"])
  }

  @MainActor @Test func splashShowsLoadingUntilSlowPreparationEnds() async throws {
    let (model, _, _) = try splash(animation: .milliseconds(50), extraDelay: .milliseconds(400))
    let elapsed = await ContinuousClock().measure { await model.run() }
    #expect(model.showsLoading)
    #expect(model.isReady)
    // 넘어가는 동안 마지막 안내 문구를 유지한다
    #expect(model.step == .connecting)
    #expect(elapsed < .seconds(2))
  }

  @MainActor @Test func splashMovesOnAfterLoadingLimit() async throws {
    let (model, _, _) = try splash(
      animation: .milliseconds(50), limit: .milliseconds(200), extraDelay: .seconds(2))
    let elapsed = await ContinuousClock().measure { await model.run() }
    #expect(model.isFinished)
    #expect(model.showsLoading)
    #expect(!model.isReady)
    #expect(elapsed < .seconds(1))
  }

  @MainActor @Test func splashTreatsConnectionFailureAsReady() async throws {
    let (model, _, _) = try splash { _, _ in
      (500, #"{"error":{"code":"INTERNAL","message":"x"}}"#)
    }
    await model.run()
    #expect(model.isFinished)
    #expect(!model.showsLoading)
  }

  @MainActor @Test func splashSkipsInterviewCleanupBeforeStart() async throws {
    let (model, store, recorder) = try splash(storedId: "i1", hasStarted: false)
    await model.run()
    #expect(recorder.items == ["GET /v1/status"])
    #expect(store.interviewId == "i1")
  }

  @MainActor @Test func splashDeletesUnfinishedInterviewAfterStart() async throws {
    let (model, store, recorder) = try splash(storedId: "i1", hasStarted: true) { method, path in
      switch (method, path) {
      case ("GET", "/v1/status"): (200, #"{"aiEnabled":true}"#)
      case ("DELETE", _): (204, "")
      default: (200, Self.detail(status: "in_progress"))
      }
    }
    await model.run()
    #expect(
      recorder.items == [
        "GET /v1/status", "GET /v1/interviews/i1", "DELETE /v1/interviews/i1",
      ])
    #expect(store.interviewId == nil)
    #expect(!model.showsLoading)
  }

  @Test func reportsNetworkFailure() async {
    StubURLProtocol.handler = nil
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 1
    let offline = APIClient(
      baseURL: URL(string: "http://127.0.0.1:9")!,
      tokenStore: DeviceTokenStore(service: "test.\(UUID().uuidString)"),
      session: URLSession(configuration: configuration))
    await #expect(throws: APIError.network) { try await offline.status() }
  }
}

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

struct AppSettingsTests {
  @Test func questionCountDefaultsAndClamps() throws {
    let defaults = try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)"))
    #expect(AppSettings.questionCount(in: defaults) == 5)
    AppSettings.setQuestionCount(9, in: defaults)
    #expect(AppSettings.questionCount(in: defaults) == 7)
    AppSettings.setQuestionCount(1, in: defaults)
    #expect(AppSettings.questionCount(in: defaults) == 3)
  }

  @Test func hasStartedDefaultsToFalseAndCanBeReset() throws {
    let defaults = try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)"))
    #expect(AppSettings.hasStarted(in: defaults) == false)
    AppSettings.setHasStarted(true, in: defaults)
    #expect(AppSettings.hasStarted(in: defaults))
    AppSettings.setHasStarted(false, in: defaults)
    #expect(AppSettings.hasStarted(in: defaults) == false)
  }
}
