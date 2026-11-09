import Foundation

@testable import FirstStepToCareer

// UseCase·ViewModel 테스트용 가짜 부품. 서버나 기기 없이 메모리에서만 동작하고, 받은 요청을 순서대로 남긴다.
// 테스트는 한 부품을 한 작업에서만 쓰므로 잠그지 않는다

struct FakeError: RepositoryError, Equatable {
  var isRejected = false
  var isAIDisabled = false
  var isConnectionFailure = false

  static let rejected = FakeError(isRejected: true)
  static let aiDisabled = FakeError(isAIDisabled: true)
  static let offline = FakeError(isConnectionFailure: true)
  static let other = FakeError()
}

final class FakeInterviewRepository: InterviewRepository, @unchecked Sendable {
  var calls: [String] = []
  var details: [String: InterviewDetail] = [:]
  var summaries: [InterviewSummary] = []
  var answerResult = AnswerResult(status: .inProgress, nextQuestion: nil, closingMessage: nil)
  var failures: [String: FakeError] = [:]

  private func record(_ call: String) throws {
    calls.append(call)
    if let error = failures[call.components(separatedBy: " ")[0]] { throw error }
  }

  func create(_ interview: NewInterview) async throws -> InterviewDetail {
    try record("create")
    return details["new"] ?? FakeData.detail(id: "new", status: .inProgress)
  }

  func detail(id: String) async throws -> InterviewDetail {
    try record("detail \(id)")
    return details[id] ?? FakeData.detail(id: id, status: .inProgress)
  }

  func all() async throws -> [InterviewSummary] {
    try record("all")
    return summaries
  }

  func delete(id: String) async throws {
    try record("delete \(id)")
  }

  func submitAnswer(_ answer: AnswerSubmission, interviewId: String, questionId: String)
    async throws -> AnswerResult
  {
    try record("submit \(interviewId) \(questionId) \(answer.transcript)")
    return answerResult
  }

  func evaluate(id: String) async throws -> InterviewDetail {
    try record("evaluate \(id)")
    return FakeData.detail(id: id, status: .completed)
  }
}

final class FakeAccountRepository: AccountRepository, @unchecked Sendable {
  var calls: [String] = []
  var accountType = AccountType.guest
  var failure: FakeError?

  private func record(_ call: String) throws {
    calls.append(call)
    if let failure { throw failure }
  }

  func status() async throws -> AccountStatus {
    try record("status")
    return AccountStatus(accountType: accountType)
  }

  func signInWithApple(_ request: AppleSignInRequest) async throws -> AccountStatus {
    try record("signIn \(request.nonce)")
    return AccountStatus(accountType: .apple)
  }

  func signOut() async throws { try record("signOut") }
  func deleteAllData() async throws { try record("deleteAllData") }
}

final class FakeProfileRepository: ProfileRepository, @unchecked Sendable {
  var calls: [String] = []
  var stored: Profile?
  var failures: [String: FakeError] = [:]
  // 서버가 정리해 돌려주는 값. nil이면 보낸 값을 그대로 돌려준다
  var savedResponse: Profile?

  private func record(_ call: String) throws {
    calls.append(call)
    if let error = failures[call.components(separatedBy: " ")[0]] { throw error }
  }

  func fetch() async throws -> Profile? {
    try record("fetch")
    return stored
  }

  func save(_ profile: Profile) async throws -> Profile? {
    try record("save \(profile.nickname)")
    stored = savedResponse ?? profile
    return stored
  }

  func recordConsents(to documents: [LegalDocument]) async throws {
    try record("consents \(documents.map(\.rawValue).joined(separator: ","))")
  }
}

final class FakeServiceStatusRepository: ServiceStatusRepository, @unchecked Sendable {
  var calls = 0
  var aiEnabled = true
  var failure: FakeError?

  func isAIEnabled() async throws -> Bool {
    calls += 1
    if let failure { throw failure }
    return aiEnabled
  }
}

final class MemoryAppSettings: AppSettingsRepository, @unchecked Sendable {
  var questionCount = InterviewDraft.defaultQuestionCount
  var hasStarted = false
  var hasChosenStart = false
  var hasAgreed = false
  var hasOutdatedAgreement = false

  func setQuestionCount(_ value: Int) {
    let range = InterviewDraft.questionCountRange
    questionCount = min(max(value, range.lowerBound), range.upperBound)
  }

  func setHasStarted(_ value: Bool) { hasStarted = value }
  func setHasChosenStart(_ value: Bool) { hasChosenStart = value }

  func saveAgreement() {
    hasAgreed = true
    hasOutdatedAgreement = false
  }

  func clearAgreement() {
    hasAgreed = false
    hasOutdatedAgreement = false
  }
}

final class MemoryProfileCache: ProfileCacheRepository, @unchecked Sendable {
  var profile: Profile?

  func save(_ profile: Profile) { self.profile = profile }
  func clear() { profile = nil }
}

final class MemoryActiveInterview: ActiveInterviewRepository, @unchecked Sendable {
  var interviewId: String?

  func save(_ id: String) { interviewId = id }
  func clear() { interviewId = nil }
}

struct FakeNonces: SignInNonceGenerating {
  func make() -> String { "raw-nonce" }
  func sha256Hex(_ value: String) -> String { "hash(\(value))" }
}

@MainActor
final class FakeFaceTracker: FaceTracking {
  var currentSample: FaceSample?
  var samples: [FaceSample?] = []
  var calls: [String] = []

  func start() { calls.append("start") }
  func stop() { calls.append("stop") }

  func collectSamples(duration: TimeInterval) async -> [FaceSample?] {
    calls.append("collect \(Int(duration))")
    return samples
  }
}

enum FakeData {
  static func detail(id: String, status: InterviewStatus, questions: [Question]? = nil)
    -> InterviewDetail
  {
    InterviewDetail(
      id: id, companyName: "A", industry: "IT", jobTitle: "SE", interviewType: .hr,
      hiringType: .newGrad, questionCount: 3, faceTracking: false, status: status,
      startedAt: "2026-11-06T00:00:00.000Z", completedAt: nil, scores: nil, feedback: nil,
      closingMessage: nil,
      questions: questions ?? [Question(id: "q1", position: 1, preface: "p", text: "t")])
  }

  static func summary(id: String, status: InterviewStatus, total: Double? = nil)
    -> InterviewSummary
  {
    InterviewSummary(
      id: id, companyName: "A", industry: "IT", jobTitle: "SE", interviewType: .hr,
      hiringType: .newGrad, status: status, startedAt: "2026-11-06T00:00:00.000Z",
      completedAt: status == .completed ? "2026-11-06T00:10:00.000Z" : nil,
      scores: total.map {
        InterviewScores(total: $0, structure: $0, logic: $0, gaze: nil, head: nil)
      })
  }
}
