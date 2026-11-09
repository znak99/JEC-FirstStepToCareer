import Foundation
import Testing

@testable import FirstStepToCareer

// 면접 진행 화면 상태. 가짜 음성 부품으로 시뮬레이터에서 해 볼 수 없는 답변 흐름까지 확인한다
@MainActor
struct InterviewSessionViewModelTests {
  let interviews = FakeInterviewRepository()
  let active = MemoryActiveInterview()
  let devices = FakeInterviewDevices()

  private func makeModel() -> InterviewSessionViewModel {
    let detail = FakeData.detail(
      id: "i1", status: .inProgress,
      questions: [Question(id: "q1", position: 1, preface: "本日は", text: "自己紹介を")])
    let context = InterviewSessionContext(
      interview: detail, tracker: nil, baseline: nil, frontCamera: nil)
    return InterviewSessionViewModel(
      context: context,
      submitAnswer: SubmitAnswerUseCase(interviews: interviews, activeInterview: active),
      quitInterview: QuitInterviewUseCase(interviews: interviews, activeInterview: active),
      devices: devices)
  }

  private static let next = AnswerResult(
    status: .inProgress,
    nextQuestion: Question(id: "q2", position: 2, preface: "なるほど", text: "志望動機を"),
    closingMessage: nil)

  @Test func answersEachQuestionAndFinishes() async {
    active.save("i1")
    let model = makeModel()
    await model.start()
    #expect(devices.audio.calls == ["activate"])
    #expect(devices.synthesizer.spoken == ["本日は\n自己紹介を"])
    #expect(model.phase == .listening)

    devices.recognizer.transcript = "  はい、学生です。 "
    interviews.answerResult = Self.next
    await model.finishAnswer()
    #expect(interviews.calls == ["submit i1 q1 はい、学生です。"])
    #expect(model.question.id == "q2")
    #expect(devices.synthesizer.spoken.last == "なるほど\n志望動機を")
    #expect(model.phase == .listening)
    // 새 질문에서는 받아쓴 글을 비운다
    #expect(model.transcript.isEmpty)
    #expect(active.interviewId == "i1")

    devices.recognizer.transcript = "御社が好きです"
    interviews.answerResult = AnswerResult(
      status: .awaitingEvaluation, nextQuestion: nil, closingMessage: "以上です")
    await model.finishAnswer()
    #expect(devices.synthesizer.spoken.last == "以上です")
    #expect(model.phase == .finished)
    #expect(active.interviewId == nil)
    #expect(devices.audio.calls == ["activate", "deactivate"])
    #expect(!devices.recognizer.isListening)
  }

  @Test func emptyAnswerAsksAgainWithoutSending() async {
    let model = makeModel()
    await model.start()
    devices.recognizer.transcript = "   "
    await model.finishAnswer()
    #expect(interviews.calls.isEmpty)
    #expect(model.notice == "回答を聞き取れませんでした。もう一度お話しください。")
    #expect(model.phase == .listening)
    // 다시 들을 때 받아쓴 글을 지우지 않는다
    #expect(devices.recognizer.calls == ["reset", "start", "stop", "start"])
  }

  @Test func failedAnswerShowsReasonAndRetries() async {
    let model = makeModel()
    await model.start()
    devices.recognizer.transcript = "はい"
    interviews.failures["submit"] = .aiDisabled
    await model.finishAnswer()
    #expect(model.phase == .failed(ErrorMessage.aiDisabled))
    interviews.failures = [:]
    interviews.answerResult = Self.next
    await model.retry()
    #expect(interviews.calls == ["submit i1 q1 はい", "submit i1 q1 はい"])
    #expect(model.question.id == "q2")
    #expect(model.phase == .listening)
  }

  @Test func pauseAndResumeKeepTheAnswer() async {
    let model = makeModel()
    await model.start()
    devices.recognizer.transcript = "はい"
    #expect(model.canPause)
    model.pause()
    #expect(model.phase == .paused)
    #expect(!devices.recognizer.isListening)
    await model.resume()
    #expect(model.phase == .listening)
    #expect(model.transcript == "はい")
  }

  @Test func quitDeletesInterviewAndReleasesDevices() async {
    active.save("i1")
    let model = makeModel()
    await model.start()
    await model.quit()
    #expect(interviews.calls == ["delete i1"])
    #expect(active.interviewId == nil)
    #expect(devices.audio.calls.last == "deactivate")
    #expect(devices.synthesizer.stops > 0)
  }

  @Test func audioFailureStopsBeforeAsking() async {
    devices.audio.fails = true
    let model = makeModel()
    await model.start()
    #expect(model.phase == .failed("音声を利用できませんでした。"))
    #expect(devices.synthesizer.spoken.isEmpty)
  }

  @Test func recognitionFailureIsReported() async {
    devices.recognizer.failsToStart = true
    let model = makeModel()
    await model.start()
    #expect(model.phase == .failed("音声認識を開始できませんでした。"))
  }
}

// 면접 준비 화면 상태
@MainActor
struct PreparationViewModelTests {
  let status = FakeServiceStatusRepository()
  let interviews = FakeInterviewRepository()
  let active = MemoryActiveInterview()
  let devices = FakeInterviewDevices()

  private func makeModel() -> PreparationViewModel {
    var draft = InterviewDraft()
    draft.industry = "IT"
    draft.jobTitle = "SE"
    return PreparationViewModel(
      draft: draft, checkServiceStatus: CheckServiceStatusUseCase(status: status),
      calibrateFace: CalibrateFaceUseCase(),
      startInterview: StartInterviewUseCase(interviews: interviews, activeInterview: active),
      devices: devices)
  }

  private static let steady = FaceSample(
    gaze: Direction(yaw: 2, pitch: 1), head: Direction(yaw: 1, pitch: 0))

  @Test func checksPassWithoutCameraAndStarts() async {
    let model = makeModel()
    await model.runChecks()
    #expect(model.requiredChecksPassed)
    #expect(model.camera == .unavailable)
    #expect(model.face == .skipped("この端末は視線・頭の動きの計測に対応していません。"))
    #expect(model.canStart)
    let context = await model.start()
    #expect(context?.interview.id == "new")
    #expect(context?.tracker == nil && context?.baseline == nil)
    #expect(active.interviewId == "new")
  }

  @Test func failedChecksExplainWhyAndRecheck() async {
    devices.caps.hasJapaneseVoice = false
    devices.caps.speechAllowed = false
    status.aiEnabled = false
    let model = makeModel()
    await model.runChecks()
    #expect(
      model.failureMessages == [
        "日本語の読み上げ音声を利用できません。", "マイクと音声認識の許可が必要です。設定アプリで許可してください。",
        ErrorMessage.aiDisabled,
      ])
    #expect(!model.canStart)
    devices.caps.hasJapaneseVoice = true
    devices.caps.speechAllowed = true
    devices.recognizer.isAvailable = false
    status.failure = .offline
    await model.recheck()
    #expect(model.failureMessages == ["日本語の音声認識を利用できません。", "サーバーに接続できませんでした。"])
    devices.recognizer.isAvailable = true
    status.failure = nil
    status.aiEnabled = true
    await model.recheck()
    #expect(model.requiredChecksPassed && model.canStart)
  }

  @Test func faceTrackingCalibratesThenStartsWithBaseline() async {
    let tracker = FakePreviewTracker()
    tracker.samples = Array(repeating: Self.steady, count: 10)
    devices.faceTracker = tracker
    let model = makeModel()
    await model.runChecks()
    #expect(model.camera == .faceTracking)
    #expect(model.face == .ready)
    #expect(tracker.calls == ["start"])
    #expect(!model.canStart && model.canCalibrate)
    await model.calibrate()
    #expect(model.baseline == FaceBaseline.make(from: tracker.samples))
    #expect(model.canStart)
    let context = await model.start()
    #expect(context?.tracker != nil && context?.baseline != nil)
  }

  @Test func unstableFaceSkipsButCanCalibrateAgain() async {
    let tracker = FakePreviewTracker()
    tracker.samples = Array(repeating: nil, count: 10)
    devices.faceTracker = tracker
    let model = makeModel()
    await model.runChecks()
    await model.calibrate()
    #expect(
      model.face == .skipped("顔を安定して認識できなかったため、視線・頭の動きは評価されません。"))
    #expect(model.isRetryableSkip && model.canCalibrate && model.canStart)
    tracker.samples = Array(repeating: Self.steady, count: 10)
    await model.calibrate()
    #expect(model.baseline != nil)
  }

  @Test func deniedCameraSkipsMeasurement() async {
    devices.faceTracker = FakePreviewTracker()
    devices.caps.cameraAllowed = false
    let model = makeModel()
    await model.runChecks()
    #expect(model.camera == .denied)
    #expect(model.face == .skipped("カメラが許可されていないため、視線・頭の動きは評価されません。"))
    #expect(model.canStart)
  }

  @Test func frontCameraMirrorsWithoutFaceTracking() async {
    let camera = FakeFrontCamera()
    devices.frontCamera = camera
    devices.caps.hasFrontCamera = true
    let model = makeModel()
    await model.runChecks()
    #expect(model.camera == .mirror)
    #expect(camera.calls == ["start"])
    let context = await model.start()
    #expect(context?.frontCamera != nil && context?.tracker == nil)
    model.leave()
    #expect(camera.calls == ["start", "stop"])
  }

  @Test func aiTurnedOffBeforeStartMarksServerCheck() async {
    let model = makeModel()
    await model.runChecks()
    interviews.failures["create"] = .aiDisabled
    #expect(await model.start() == nil)
    #expect(model.server == .failed(ErrorMessage.aiDisabled))
    #expect(model.startError == nil)
    #expect(active.interviewId == nil)
  }

  @Test func otherStartFailureShowsMessage() async {
    let model = makeModel()
    await model.runChecks()
    interviews.failures["create"] = .offline
    #expect(await model.start() == nil)
    #expect(model.startError == "面接を開始できませんでした。もう一度お試しください。")
    #expect(model.server == .passed)
  }
}

// 면접 홈과 면접 결과 화면 상태
@MainActor
struct InterviewHomeAndResultViewModelTests {
  let status = FakeServiceStatusRepository()
  let settings = MemoryAppSettings()
  let cache = MemoryProfileCache()
  let interviews = FakeInterviewRepository()

  private func home() -> InterviewHomeViewModel {
    InterviewHomeViewModel(
      checkServiceStatus: CheckServiceStatusUseCase(status: status),
      getCachedProfile: GetCachedProfileUseCase(profileCache: cache),
      getQuestionCount: GetQuestionCountUseCase(settings: settings),
      saveQuestionCount: SaveQuestionCountUseCase(settings: settings))
  }

  private func result(id: String) -> InterviewResultViewModel {
    InterviewResultViewModel(
      interviewId: id, loadInterview: LoadInterviewUseCase(interviews: interviews),
      evaluateInterview: EvaluateInterviewUseCase(interviews: interviews),
      deleteInterview: DeleteInterviewUseCase(interviews: interviews))
  }

  @Test func homeShowsAIStatus() async {
    let model = home()
    #expect(model.availability == .loading)
    await model.refresh()
    #expect(model.availability == .available)
    status.aiEnabled = false
    await model.refresh()
    #expect(model.availability == .aiDisabled)
    status.failure = .offline
    await model.refresh()
    #expect(model.availability == .failed)
    model.retry()
    #expect(model.availability == .loading)
  }

  @Test func homeFillsFromProfileAndRemembersQuestionCount() {
    settings.setQuestionCount(6)
    cache.save(Profile(saved: "太郎", hiringType: .midCareer, industry: "商社", jobTitle: nil))
    let model = home()
    #expect(model.form.questionCount == 6)
    #expect(model.form.hiringType == .midCareer)
    cache.save(Profile(saved: "太郎", hiringType: .newGrad, industry: nil, jobTitle: nil))
    model.syncProfile()
    #expect(model.form.hiringType == .newGrad)
    model.saveQuestionCount(4)
    #expect(settings.questionCount == 4)
  }

  @Test func resultEvaluatesAwaitingInterview() async {
    interviews.details["wait"] = FakeData.detail(id: "wait", status: .awaitingEvaluation)
    let model = result(id: "wait")
    await model.load()
    #expect(model.state == .loaded(FakeData.detail(id: "wait", status: .completed)))
    #expect(interviews.calls == ["detail wait", "evaluate wait"])
  }

  @Test func resultDoesNotEvaluateFinishedInterview() async {
    interviews.details["done"] = FakeData.detail(id: "done", status: .completed)
    let model = result(id: "done")
    await model.load()
    #expect(model.state == .loaded(FakeData.detail(id: "done", status: .completed)))
    #expect(interviews.calls == ["detail done"])
  }

  @Test func resultShowsFailuresAndDeletes() async {
    interviews.failures["detail"] = .offline
    let model = result(id: "x")
    await model.load()
    #expect(model.state == .failed("サーバーに接続できませんでした。通信環境を確認してください。"))
    interviews.failures = ["delete": .other]
    #expect(await model.delete() == false)
    #expect(model.state == .failed("削除できませんでした。もう一度お試しください。"))
    interviews.failures = [:]
    #expect(await model.delete())
  }
}
