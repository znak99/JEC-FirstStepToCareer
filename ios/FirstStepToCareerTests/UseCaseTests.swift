import Foundation
import Testing

@testable import FirstStepToCareer

// 앱 시작과 온보딩
struct LaunchUseCaseTests {
  let settings = MemoryAppSettings()
  let cache = MemoryProfileCache()
  let active = MemoryActiveInterview()
  let interviews = FakeInterviewRepository()
  let status = FakeServiceStatusRepository()

  @Test func launchStateReflectsSettingsAndProfile() {
    let launch = GetLaunchStateUseCase(settings: settings, profileCache: cache)
    #expect(launch.execute().stage == .consent)
    AcceptTermsUseCase(settings: settings).execute()
    #expect(launch.execute().stage == .start)
    ChooseStartUseCase(settings: settings).execute()
    #expect(launch.execute().stage == .profile)
    cache.save(Profile(saved: "太郎", hiringType: nil, industry: nil, jobTitle: nil))
    CompleteOnboardingUseCase(settings: settings).execute()
    #expect(launch.execute().stage == .tabs)
    #expect(!launch.execute().asksAgreementOverTabs)
    settings.hasAgreed = false
    settings.hasOutdatedAgreement = true
    let outdated = launch.execute()
    #expect(outdated.stage == .tabs && outdated.asksAgreementOverTabs)
    #expect(outdated.hasOutdatedAgreement)
  }

  @Test func resetClearsEverythingOnThisPhone() {
    settings.saveAgreement()
    settings.setHasChosenStart(true)
    settings.setHasStarted(true)
    settings.setQuestionCount(7)
    cache.save(Profile(saved: "太郎", hiringType: nil, industry: nil, jobTitle: nil))
    active.save("i1")
    ResetLocalDataUseCase(settings: settings, profileCache: cache, activeInterview: active)
      .execute()
    let state = GetLaunchStateUseCase(settings: settings, profileCache: cache).execute()
    #expect(
      state
        == LaunchState(
          hasAgreed: false, hasStarted: false, hasChosenStart: false, hasProfile: false,
          hasOutdatedAgreement: false))
    #expect(active.interviewId == nil)
    // 질문 수는 계정과 관계없는 이 iPhone의 설정이라 남긴다
    #expect(settings.questionCount == 7)
  }

  @Test func checkServiceStatusPassesThroughSwitchAndFailure() async throws {
    let check = CheckServiceStatusUseCase(status: status)
    #expect(try await check.execute())
    status.aiEnabled = false
    #expect(try await check.execute() == false)
    status.failure = .offline
    await #expect(throws: FakeError.offline) { try await check.execute() }
  }

  @Test func deletesUnfinishedInterviewOnlyWhileInProgress() async {
    let delete = DeleteUnfinishedInterviewUseCase(interviews: interviews, activeInterview: active)
    #expect(!delete.hasUnfinishedInterview)
    await delete.execute()
    #expect(interviews.calls.isEmpty)
    active.save("i1")
    #expect(delete.hasUnfinishedInterview)
    await delete.execute()
    #expect(interviews.calls == ["detail i1", "delete i1"])
    #expect(active.interviewId == nil)
    // 마지막 답변 직후에 꺼진 면접은 평가 대기라 지우지 않고 ID만 지운다
    active.save("i2")
    interviews.details["i2"] = FakeData.detail(id: "i2", status: .awaitingEvaluation)
    await delete.execute()
    #expect(interviews.calls.suffix(1) == ["detail i2"])
    #expect(active.interviewId == nil)
  }

  @Test func keepsUnfinishedIdUnlessServerRejects() async {
    let delete = DeleteUnfinishedInterviewUseCase(interviews: interviews, activeInterview: active)
    active.save("i1")
    interviews.failures["delete"] = .offline
    await delete.execute()
    #expect(active.interviewId == "i1")
    interviews.failures = ["detail": .rejected]
    await delete.execute()
    #expect(active.interviewId == nil)
  }

  @Test func evaluatesOnlyAwaitingInterviewsWhenAIIsOn() async {
    interviews.summaries = [
      FakeData.summary(id: "a", status: .awaitingEvaluation),
      FakeData.summary(id: "b", status: .completed, total: 80),
      FakeData.summary(id: "c", status: .awaitingEvaluation),
      FakeData.summary(id: "d", status: .inProgress),
    ]
    let evaluate = EvaluatePendingInterviewsUseCase(status: status, interviews: interviews)
    status.aiEnabled = false
    await evaluate.execute()
    #expect(interviews.calls.isEmpty)
    status.aiEnabled = true
    interviews.failures["evaluate"] = .other
    await evaluate.execute()
    // 하나가 실패해도 나머지를 계속 평가한다
    #expect(interviews.calls == ["all", "evaluate a", "evaluate c"])
  }
}

// 계정
struct AccountUseCaseTests {
  let accounts = FakeAccountRepository()

  @Test func signInChallengeHashesTheSameNonce() {
    let challenge = MakeSignInChallengeUseCase(nonces: FakeNonces()).execute()
    #expect(challenge == SignInChallenge(nonce: "raw-nonce", hashedNonce: "hash(raw-nonce)"))
  }

  @Test func accountActionsGoToRepository() async throws {
    #expect(try await GetAccountTypeUseCase(accounts: accounts).execute() == .guest)
    #expect(
      try await SignInWithAppleUseCase(accounts: accounts).execute(
        AppleSignInRequest(identityToken: "t", nonce: "n")) == .apple)
    try await SignOutUseCase(accounts: accounts).execute()
    try await DeleteAllDataUseCase(accounts: accounts).execute()
    #expect(accounts.calls == ["status", "signIn n", "signOut", "deleteAllData"])
    accounts.failure = .rejected
    await #expect(throws: FakeError.rejected) {
      try await SignOutUseCase(accounts: accounts).execute()
    }
  }
}

// 프로필
struct ProfileUseCaseTests {
  let profiles = FakeProfileRepository()
  let cache = MemoryProfileCache()
  let taro = Profile(saved: "太郎", hiringType: .newGrad, industry: nil, jobTitle: nil)
  let hanako = Profile(saved: "花子", hiringType: nil, industry: "商社", jobTitle: nil)

  @Test func loadPrefersServerAndKeepsCopy() async {
    let load = LoadProfileUseCase(profiles: profiles, profileCache: cache)
    cache.save(hanako)
    profiles.stored = taro
    #expect(await load.execute() == taro)
    #expect(cache.profile == taro)
  }

  @Test func loadFallsBackToCopyWhenServerHasNoneOrFails() async {
    let load = LoadProfileUseCase(profiles: profiles, profileCache: cache)
    cache.save(hanako)
    #expect(await load.execute() == hanako)
    profiles.stored = taro
    profiles.failures["fetch"] = .offline
    #expect(await load.execute() == hanako)
  }

  @Test func saveRecordsConsentsFirstThenKeepsServerValue() async throws {
    let save = SaveProfileUseCase(profiles: profiles, profileCache: cache)
    profiles.savedResponse = hanako
    try await save.execute(taro, agreeingTo: LegalDocument.allCases)
    #expect(profiles.calls == ["consents terms,privacy", "save 太郎"])
    #expect(cache.profile == hanako)
    try await save.execute(taro)
    #expect(profiles.calls.suffix(1) == ["save 太郎"])
  }

  @Test func saveStopsWhenConsentsFail() async {
    let save = SaveProfileUseCase(profiles: profiles, profileCache: cache)
    profiles.failures["consents"] = .offline
    await #expect(throws: FakeError.offline) {
      try await save.execute(taro, agreeingTo: LegalDocument.allCases)
    }
    #expect(profiles.calls == ["consents terms,privacy"])
    #expect(cache.profile == nil)
  }

  @Test func recordConsentsAndCachedProfile() async throws {
    try await RecordConsentsUseCase(profiles: profiles).execute([.terms])
    #expect(profiles.calls == ["consents terms"])
    #expect(GetCachedProfileUseCase(profileCache: cache).execute() == nil)
    cache.save(taro)
    #expect(GetCachedProfileUseCase(profileCache: cache).execute() == taro)
  }
}

// 모의면접
struct InterviewUseCaseTests {
  let settings = MemoryAppSettings()
  let interviews = FakeInterviewRepository()
  let active = MemoryActiveInterview()

  private var draft: InterviewDraft {
    var draft = InterviewDraft()
    draft.companyName = "A"
    draft.industry = "IT"
    draft.jobTitle = "SE"
    draft.questionCount = 4
    return draft
  }

  @Test func questionCountIsKeptWithinRange() {
    SaveQuestionCountUseCase(settings: settings).execute(1)
    #expect(GetQuestionCountUseCase(settings: settings).execute() == 3)
    SaveQuestionCountUseCase(settings: settings).execute(6)
    #expect(GetQuestionCountUseCase(settings: settings).execute() == 6)
  }

  @Test func startRemembersInterviewOnThisPhone() async throws {
    let detail = try await StartInterviewUseCase(interviews: interviews, activeInterview: active)
      .execute(draft, faceTracking: true)
    #expect(detail.id == "new")
    #expect(active.interviewId == "new")
    interviews.failures["create"] = .aiDisabled
    active.clear()
    await #expect(throws: FakeError.aiDisabled) {
      try await StartInterviewUseCase(interviews: interviews, activeInterview: active)
        .execute(draft, faceTracking: false)
    }
    #expect(active.interviewId == nil)
  }

  @Test func lastAnswerForgetsInterviewId() async throws {
    let submit = SubmitAnswerUseCase(interviews: interviews, activeInterview: active)
    let answer = AnswerSubmission(transcript: "はい", durationMs: 1, gaze: nil, head: nil)
    active.save("i1")
    interviews.answerResult = AnswerResult(
      status: .inProgress, nextQuestion: Question(id: "q2", position: 2, preface: nil, text: "t"),
      closingMessage: nil)
    _ = try await submit.execute(answer, interviewId: "i1", questionId: "q1")
    #expect(active.interviewId == "i1")
    interviews.answerResult = AnswerResult(
      status: .awaitingEvaluation, nextQuestion: nil, closingMessage: "以上です")
    let last = try await submit.execute(answer, interviewId: "i1", questionId: "q2")
    #expect(last.closingMessage == "以上です")
    #expect(active.interviewId == nil)
    #expect(interviews.calls == ["submit i1 q1 はい", "submit i1 q2 はい"])
  }

  @Test func failedAnswerKeepsInterviewId() async {
    let submit = SubmitAnswerUseCase(interviews: interviews, activeInterview: active)
    active.save("i1")
    interviews.failures["submit"] = .other
    await #expect(throws: FakeError.other) {
      try await submit.execute(
        AnswerSubmission(transcript: "はい", durationMs: 1, gaze: nil, head: nil),
        interviewId: "i1", questionId: "q1")
    }
    #expect(active.interviewId == "i1")
  }

  @Test func quitForgetsIdOnlyWhenDeleted() async {
    let quit = QuitInterviewUseCase(interviews: interviews, activeInterview: active)
    active.save("i1")
    interviews.failures["delete"] = .offline
    await quit.execute(interviewId: "i1")
    #expect(active.interviewId == "i1")
    interviews.failures = [:]
    await quit.execute(interviewId: "i1")
    #expect(active.interviewId == nil)
    #expect(interviews.calls == ["delete i1", "delete i1"])
  }

  @MainActor @Test func calibrationNeedsSteadyFace() async {
    let tracker = FakeFaceTracker()
    let steady = FaceSample(
      gaze: Direction(yaw: 2, pitch: 1), head: Direction(yaw: 1, pitch: 0))
    tracker.samples = Array(repeating: steady, count: 10)
    let baseline = await CalibrateFaceUseCase().execute(with: tracker)
    #expect(baseline == FaceBaseline.make(from: tracker.samples))
    #expect(baseline != nil)
    #expect(tracker.calls == ["collect 3"])
    tracker.samples = Array(repeating: nil, count: 10)
    #expect(await CalibrateFaceUseCase().execute(with: tracker) == nil)
  }

  @MainActor @Test func resultEvaluatesOnlyWhenAwaiting() async throws {
    let load = LoadInterviewResultUseCase(interviews: interviews)
    var evaluating = 0
    interviews.details["done"] = FakeData.detail(id: "done", status: .completed)
    #expect(try await load.execute(id: "done") { evaluating += 1 }.status == .completed)
    #expect(evaluating == 0)
    interviews.details["wait"] = FakeData.detail(id: "wait", status: .awaitingEvaluation)
    #expect(try await load.execute(id: "wait") { evaluating += 1 }.status == .completed)
    #expect(evaluating == 1)
    #expect(interviews.calls == ["detail done", "detail wait", "evaluate wait"])
  }

  @Test func deleteAndCompletedList() async throws {
    try await DeleteInterviewUseCase(interviews: interviews).execute(id: "x")
    interviews.summaries = [
      FakeData.summary(id: "a", status: .completed, total: 70),
      FakeData.summary(id: "b", status: .awaitingEvaluation),
    ]
    let list = try await LoadCompletedInterviewsUseCase(interviews: interviews).execute()
    #expect(list.map(\.id) == ["a"])
    #expect(interviews.calls == ["delete x", "all"])
  }
}
