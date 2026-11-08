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

  // 인식이 불안정해 건너뛴 경우. 이때만 기준점을 다시 잡을 수 있다
  private static let unstableFace = String(
    localized: "顔を安定して認識できなかったため、視線・頭の動きは評価されません。")
  private static let aiDisabled = String(localized: "現在、AI機能は停止中です。")

  let draft: InterviewDraft
  private(set) var speech = CheckState.checking
  private(set) var recognition = CheckState.checking
  private(set) var server = CheckState.checking
  private(set) var face = FaceState.checking
  // 카메라 자리에 무엇을 보여 줄지. 정하기 전에는 nil
  private(set) var camera: PreparationCamera?
  private(set) var isStarting = false
  private(set) var startError: String?
  let tracker: FaceTracker? = FaceTracker.isSupported ? FaceTracker() : nil
  // Face ID 카메라가 없는 iPhone에서 거울처럼 보여 줄 앞쪽 카메라
  let frontCamera: FrontCamera? =
    !FaceTracker.isSupported && FrontCamera.isAvailable ? FrontCamera() : nil

  private let api: APIClient

  init(draft: InterviewDraft, api: APIClient) {
    self.draft = draft
    self.api = api
  }

  var requiredChecksPassed: Bool {
    speech == .passed && recognition == .passed && server == .passed
  }

  // 실패한 필수 점검의 원인. 점검 순서대로 보여 준다
  var failureMessages: [String] {
    [speech, recognition, server].compactMap { state in
      if case .failed(let message) = state { message } else { nil }
    }
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

  var isRetryableSkip: Bool {
    tracker != nil && face == .skipped(Self.unstableFace)
  }

  // 기준점을 처음 잡거나, 잡은 뒤 다시 잡거나, 인식이 불안정해 건너뛴 뒤 다시 잡을 수 있다
  var canCalibrate: Bool {
    guard camera == .faceTracking else { return false }
    switch face {
    case .ready, .calibrated: return true
    default: return isRetryableSkip
    }
  }

  func runChecks() async {
    await checkRequired()
    if camera == nil { await prepareCamera() }
  }

  // 필수 점검만 다시 한다. 카메라와 기준점은 그대로 둔다
  func recheck() async {
    startError = nil
    await checkRequired()
  }

  private func checkRequired() async {
    speech =
      SpeechSynthesizer.isAvailable
      ? .passed : .failed(String(localized: "日本語の読み上げ音声を利用できません。"))
    recognition = .checking
    server = .checking
    async let recognitionResult = checkRecognition()
    async let serverResult = checkServer()
    recognition = await recognitionResult
    server = await serverResult
  }

  private func checkRecognition() async -> CheckState {
    guard await SpeechRecognizer.requestAuthorization() else {
      return .failed(String(localized: "マイクと音声認識の許可が必要です。設定アプリで許可してください。"))
    }
    return SpeechRecognizer().isAvailable
      ? .passed : .failed(String(localized: "日本語の音声認識を利用できません。"))
  }

  private func checkServer() async -> CheckState {
    do {
      return try await api.status().aiEnabled ? .passed : .failed(Self.aiDisabled)
    } catch {
      return .failed(String(localized: "サーバーに接続できませんでした。"))
    }
  }

  private func prepareCamera() async {
    let trackingSupported = tracker != nil
    let hasFrontCamera = FrontCamera.isAvailable
    let granted =
      PreparationCamera.needsAccess(
        trackingSupported: trackingSupported, hasFrontCamera: hasFrontCamera)
      ? await FaceTracker.requestCameraAccess() : false
    let mode = PreparationCamera.of(
      trackingSupported: trackingSupported, hasFrontCamera: hasFrontCamera, accessGranted: granted)
    camera = mode
    switch mode {
    case .faceTracking:
      tracker?.start()
      face = .ready
    case .mirror, .unavailable:
      frontCamera?.start()
      face = .skipped(String(localized: "この端末は視線・頭の動きの計測に対応していません。"))
    case .denied:
      face = .skipped(String(localized: "カメラが許可されていないため、視線・頭の動きは評価されません。"))
    }
  }

  func calibrate() async {
    guard let tracker, canCalibrate else { return }
    face = .calibrating
    let samples = await tracker.collectSamples(duration: 3)
    if let baseline = FaceBaseline.make(from: samples) {
      face = .calibrated(baseline)
    } else {
      face = .skipped(Self.unstableFace)
    }
  }

  func start() async -> InterviewSessionContext? {
    guard canStart else { return nil }
    isStarting = true
    startError = nil
    defer { isStarting = false }
    let baseline = baseline
    do {
      let interview = try await api.createInterview(draft.request(faceTracking: baseline != nil))
      ActiveInterviewStore().save(interview.id)
      if baseline == nil { tracker?.stop() }
      frontCamera?.stop()
      return InterviewSessionContext(
        interview: interview, tracker: baseline == nil ? nil : tracker, baseline: baseline)
    } catch let error as APIError where error.code == "AI_DISABLED" {
      // 점검 뒤에 AI가 꺼진 경우. 점검 표시도 실패로 맞춰 다시 점검할 수 있게 한다
      server = .failed(Self.aiDisabled)
    } catch {
      startError = String(localized: "面接を開始できませんでした。もう一度お試しください。")
    }
    return nil
  }

  func leave() {
    tracker?.stop()
    frontCamera?.stop()
  }
}
