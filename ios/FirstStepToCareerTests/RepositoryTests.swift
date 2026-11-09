import Foundation
import Testing

@testable import FirstStepToCareer

// 서버 저장소. StubURLProtocol을 함께 쓰므로 APIClientTests(.serialized) 안에서 돈다
extension APIClientTests {
  @Test func interviewRepositoryCallsInterviewEndpoints() async throws {
    let recorder = stubRoutes { method, path in
      switch (method, path) {
      case ("GET", "/v1/interviews"):
        (
          200,
          #"{"items":["# + Self.summary(id: "a", status: "completed") + #"],"nextCursor":null}"#
        )
      case ("DELETE", _): (204, "")
      case ("PUT", _):
        (200, #"{"status":"awaiting_evaluation","nextQuestion":null,"closingMessage":"以上です"}"#)
      default: (200, Self.detail(status: method == "POST" ? "completed" : "in_progress"))
      }
    }
    let repository: any InterviewRepository = APIInterviewRepository(api: client)
    let created = try await repository.create(
      NewInterview(
        companyName: "A", industry: "IT", jobTitle: "SE", interviewType: .hr, hiringType: .newGrad,
        questionCount: 3, faceTracking: false))
    #expect(created.id == "i1")
    #expect(try await repository.detail(id: "i1").status == .inProgress)
    #expect(try await repository.all().map(\.id) == ["a"])
    let result = try await repository.submitAnswer(
      AnswerSubmission(transcript: "はい", durationMs: 1, gaze: nil, head: nil), interviewId: "i1",
      questionId: "q1")
    #expect(result.closingMessage == "以上です")
    #expect(try await repository.evaluate(id: "i1").status == .completed)
    try await repository.delete(id: "i1")
    #expect(
      recorder.items == [
        "POST /v1/interviews", "GET /v1/interviews/i1", "GET /v1/interviews",
        "PUT /v1/interviews/i1/questions/q1/answer", "POST /v1/interviews/i1/evaluation",
        "DELETE /v1/interviews/i1",
      ])
  }

  @Test func accountRepositoryCallsAccountEndpoints() async throws {
    let recorder = stubRoutes { method, path in
      switch (method, path) {
      case ("GET", "/v1/me"): (200, #"{"accountType":"guest"}"#)
      case ("POST", "/v1/auth/apple"): (200, #"{"accountType":"apple"}"#)
      default: (204, "")
      }
    }
    let repository: any AccountRepository = APIAccountRepository(api: client)
    #expect(try await repository.status().accountType == .guest)
    #expect(
      try await repository.signInWithApple(AppleSignInRequest(identityToken: "t", nonce: "n"))
        .accountType == .apple)
    try await repository.signOut()
    try await repository.deleteAllData()
    #expect(
      recorder.items == [
        "GET /v1/me", "POST /v1/auth/apple", "POST /v1/auth/logout", "DELETE /v1/me",
      ])
  }

  @Test func profileRepositoryCallsProfileEndpoints() async throws {
    var saved = false
    let recorder = stubRoutes { method, _ in
      switch method {
      case "GET": return (200, #"{"profile":null}"#)
      case "PUT":
        saved = true
        return (200, #"{"profile":{"nickname":"太郎","hiringType":"new_grad"}}"#)
      default: return (204, "")
      }
    }
    let repository: any ProfileRepository = APIProfileRepository(api: client)
    #expect(try await repository.fetch() == nil)
    let profile = Profile(saved: "太郎", hiringType: .newGrad, industry: nil, jobTitle: nil)
    #expect(try await repository.save(profile) == profile)
    try await repository.recordConsents(to: LegalDocument.allCases)
    #expect(saved)
    #expect(recorder.items == ["GET /v1/me/profile", "PUT /v1/me/profile", "POST /v1/me/consents"])
  }

  @Test func serviceStatusRepositoryReadsAISwitch() async throws {
    _ = stubRoutes { _, _ in (200, #"{"aiEnabled":false}"#) }
    let repository: any ServiceStatusRepository = APIServiceStatusRepository(api: client)
    #expect(try await repository.isAIEnabled() == false)
  }
}

// 이 iPhone의 저장값
struct LocalRepositoryTests {
  private static func defaults() throws -> UserDefaults {
    try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)"))
  }

  @Test func appSettingsKeepsSettingsAndOnboardingState() throws {
    let defaults = try Self.defaults()
    let settings: any AppSettingsRepository = LocalAppSettingsRepository(defaults: defaults)
    #expect(settings.questionCount == InterviewDraft.defaultQuestionCount)
    settings.setQuestionCount(99)
    #expect(settings.questionCount == InterviewDraft.questionCountRange.upperBound)
    #expect(!settings.hasStarted && !settings.hasChosenStart && !settings.hasAgreed)
    settings.setHasStarted(true)
    settings.setHasChosenStart(true)
    settings.saveAgreement()
    #expect(settings.hasStarted && settings.hasChosenStart && settings.hasAgreed)
    #expect(!settings.hasOutdatedAgreement)
    // 같은 저장 위치를 쓰므로 이전 버전이 남긴 값도 그대로 읽는다
    #expect(AppSettings.hasStarted(in: defaults))
    defaults.set(
      ["terms": "2000-01-01", "privacy": "2000-01-01"], forKey: "agreedDocumentVersions")
    #expect(!settings.hasAgreed && settings.hasOutdatedAgreement)
    settings.clearAgreement()
    #expect(!settings.hasAgreed && !settings.hasOutdatedAgreement)
  }

  @Test func profileCacheAndActiveInterviewKeepValues() throws {
    let defaults = try Self.defaults()
    let cache: any ProfileCacheRepository = ProfileStore(defaults: defaults)
    let profile = Profile(saved: "花子", hiringType: nil, industry: "商社", jobTitle: nil)
    cache.save(profile)
    #expect(cache.profile == profile)
    cache.clear()
    #expect(cache.profile == nil)
    let active: any ActiveInterviewRepository = ActiveInterviewStore(defaults: defaults)
    active.save("i1")
    #expect(active.interviewId == "i1")
    active.clear()
    #expect(active.interviewId == nil)
  }
}
