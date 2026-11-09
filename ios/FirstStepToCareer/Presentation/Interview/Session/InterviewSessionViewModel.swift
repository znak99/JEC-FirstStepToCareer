import Foundation
import Observation

@MainActor
@Observable
final class InterviewSessionViewModel {
  enum Phase: Equatable {
    case speaking
    case listening
    case submitting
    case closing
    case paused
    case failed(String)
    case finished
  }

  let interview: InterviewDetail
  private(set) var question: Question
  private(set) var phase = Phase.speaking
  private(set) var notice: String?

  var transcript: String { recognizer.transcript }
  var level: Float { recognizer.level }
  var canPause: Bool { phase == .speaking || phase == .listening }

  @ObservationIgnored private let api: APIClient
  @ObservationIgnored private let activeStore = ActiveInterviewStore()
  @ObservationIgnored private let synthesizer = SpeechSynthesizer()
  @ObservationIgnored private let recognizer = SpeechRecognizer()
  @ObservationIgnored private let tracker: FaceTracker?
  @ObservationIgnored private let baseline: FaceBaseline?
  @ObservationIgnored private let frontCamera: FrontCamera?
  @ObservationIgnored private var gaze = DeductionCounts()
  @ObservationIgnored private var head = DeductionCounts()
  @ObservationIgnored private var listeningSince: Date?
  @ObservationIgnored private var listenedSeconds: TimeInterval = 0
  @ObservationIgnored private var sampling: Task<Void, Never>?
  @ObservationIgnored private var pausedWhileSpeaking = false
  @ObservationIgnored private var pendingSubmission: AnswerSubmission?
  @ObservationIgnored private var started = false

  init(context: InterviewSessionContext, api: APIClient) {
    interview = context.interview
    question =
      context.interview.questions.last(where: { $0.answer == nil })
      ?? context.interview.questions[context.interview.questions.count - 1]
    tracker = context.tracker
    baseline = context.baseline
    frontCamera = context.frontCamera
    self.api = api
  }

  func start() async {
    guard !started else { return }
    started = true
    do {
      try AudioSessionConfigurator.activate()
    } catch {
      phase = .failed(String(localized: "音声を利用できませんでした。"))
      return
    }
    await ask(question)
  }

  // 맞장구와 질문을 읽은 뒤 듣기를 시작한다
  private func ask(_ question: Question) async {
    self.question = question
    phase = .speaking
    notice = nil
    let text = [question.preface, question.text].compactMap { $0 }.joined(separator: "\n")
    await synthesizer.speak(text)
    guard phase == .speaking else { return }
    beginListening(resetAnswer: true)
  }

  private func beginListening(resetAnswer: Bool) {
    if resetAnswer {
      recognizer.reset()
      gaze = DeductionCounts()
      head = DeductionCounts()
      listenedSeconds = 0
    }
    do {
      try recognizer.start()
    } catch {
      phase = .failed(String(localized: "音声認識を開始できませんでした。"))
      return
    }
    listeningSince = Date()
    phase = .listening
    startSampling()
  }

  // 답변하는 동안 1초마다 시선과 머리를 판정한다
  private func startSampling() {
    guard let tracker, let baseline else { return }
    sampling?.cancel()
    sampling = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled, let self, self.phase == .listening else { return }
        let levels = baseline.levels(for: tracker.currentSample)
        self.gaze.add(levels.gaze)
        self.head.add(levels.head)
      }
    }
  }

  private func stopListening() {
    recognizer.stop()
    sampling?.cancel()
    sampling = nil
    if let since = listeningSince {
      listenedSeconds += Date().timeIntervalSince(since)
      listeningSince = nil
    }
  }

  func finishAnswer() async {
    guard phase == .listening else { return }
    stopListening()
    let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else {
      notice = String(localized: "回答を聞き取れませんでした。もう一度お話しください。")
      beginListening(resetAnswer: false)
      return
    }
    let tracked = baseline != nil
    pendingSubmission = AnswerSubmission(
      transcript: text,
      durationMs: Int(listenedSeconds * 1000),
      gaze: tracked ? gaze : nil,
      head: tracked ? head : nil)
    await submit()
  }

  func retry() async {
    guard case .failed = phase else { return }
    if pendingSubmission != nil {
      await submit()
    } else {
      await ask(question)
    }
  }

  private func submit() async {
    guard let submission = pendingSubmission else { return }
    phase = .submitting
    do {
      let result = try await api.submitAnswer(
        interviewId: interview.id, questionId: question.id, submission)
      pendingSubmission = nil
      if let next = result.nextQuestion {
        await ask(next)
      } else {
        // 마지막 답변이 저장되어 평가 대기가 됐으므로 다음 실행 때 지우지 않게 한다
        activeStore.clear()
        phase = .closing
        await synthesizer.speak(result.closingMessage ?? "")
        finish()
      }
    } catch {
      phase = .failed(ErrorMessage.text(for: error))
    }
  }

  func pause() {
    switch phase {
    case .speaking:
      pausedWhileSpeaking = true
      phase = .paused
      synthesizer.stop()
    case .listening:
      pausedWhileSpeaking = false
      stopListening()
      phase = .paused
    default:
      break
    }
  }

  func resume() async {
    guard phase == .paused else { return }
    if pausedWhileSpeaking {
      await ask(question)
    } else {
      beginListening(resetAnswer: false)
    }
  }

  // 그만두면 면접을 지운다. 지우지 못해도 화면은 닫고, 다음 실행 때 다시 지운다
  func quit() async {
    tearDown()
    if (try? await api.deleteInterview(id: interview.id)) != nil {
      activeStore.clear()
    }
  }

  private func finish() {
    tearDown()
    phase = .finished
  }

  func tearDown() {
    synthesizer.stop()
    stopListening()
    tracker?.stop()
    frontCamera?.stop()
    AudioSessionConfigurator.deactivate()
  }
}
