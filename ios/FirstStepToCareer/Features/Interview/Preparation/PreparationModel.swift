import Foundation
import Observation

@MainActor
@Observable
final class PreparationModel {
  enum CheckState: Equatable {
    case checking
    case passed
    case failed(String)
  }

  enum FaceState: Equatable {
    case checking
    case ready
    case calibrating
    case calibrated(FaceBaseline)
    case skipped(String)
  }

  let draft: InterviewDraft
  private(set) var speech = CheckState.checking
  private(set) var recognition = CheckState.checking
  private(set) var server = CheckState.checking
  private(set) var face = FaceState.checking
  private(set) var isStarting = false
  private(set) var startError: String?
  let tracker: FaceTracker? = FaceTracker.isSupported ? FaceTracker() : nil

  private let api: APIClient

  init(draft: InterviewDraft, api: APIClient) {
    self.draft = draft
    self.api = api
  }

  var requiredChecksPassed: Bool {
    speech == .passed && recognition == .passed && server == .passed
  }

  var canStart: Bool {
    guard requiredChecksPassed, !isStarting else { return false }
    switch face {
    case .calibrated, .skipped: return true
    default: return false
    }
  }

  var baseline: FaceBaseline? {
    if case .calibrated(let value) = face { value } else { nil }
  }

  func runChecks() async {
    speech = SpeechSynthesizer.isAvailable ? .passed : .failed("日本語の読み上げ音声を利用できません。")
    recognition = .checking
    server = .checking
    async let recognitionResult = checkRecognition()
    async let serverResult = checkServer()
    recognition = await recognitionResult
    server = await serverResult
    if case .checking = face { await prepareFace() }
  }

  private func checkRecognition() async -> CheckState {
    guard await SpeechRecognizer.requestAuthorization() else {
      return .failed("マイクと音声認識の許可が必要です。設定アプリで許可してください。")
    }
    return SpeechRecognizer().isAvailable ? .passed : .failed("日本語の音声認識を利用できません。")
  }

  private func checkServer() async -> CheckState {
    do {
      return try await api.status().aiEnabled
        ? .passed : .failed("現在、AI機能は停止中です。")
    } catch {
      return .failed("サーバーに接続できませんでした。")
    }
  }

  private func prepareFace() async {
    guard let tracker else {
      face = .skipped("この端末は視線・頭の動きの計測に対応していません。")
      return
    }
    guard await FaceTracker.requestCameraAccess() else {
      face = .skipped("カメラが許可されていないため、視線・頭の動きは評価されません。")
      return
    }
    tracker.start()
    face = .ready
  }

  func calibrate() async {
    guard let tracker, face == .ready || isRetryableSkip else { return }
    face = .calibrating
    let samples = await tracker.collectSamples(duration: 3)
    if let baseline = FaceBaseline.make(from: samples) {
      face = .calibrated(baseline)
    } else {
      face = .skipped("顔を安定して認識できなかったため、視線・頭の動きは評価されません。")
    }
  }

  // 인식이 불안정해 건너뛴 경우에만 기준점을 다시 잡을 수 있다
  var isRetryableSkip: Bool {
    guard tracker != nil, case .skipped(let reason) = face else { return false }
    return reason.hasPrefix("顔を")
  }

  func start() async -> InterviewSessionContext? {
    guard canStart else { return nil }
    isStarting = true
    startError = nil
    defer { isStarting = false }
    let baseline = baseline
    do {
      let interview = try await api.createInterview(draft.request(faceTracking: baseline != nil))
      if baseline == nil { tracker?.stop() }
      return InterviewSessionContext(
        interview: interview, tracker: baseline == nil ? nil : tracker, baseline: baseline)
    } catch let error as APIError where error.code == "AI_DISABLED" {
      startError = "現在、AI機能は停止中です。"
    } catch {
      startError = "面接を開始できませんでした。もう一度お試しください。"
    }
    return nil
  }

  func leave() {
    tracker?.stop()
  }
}
