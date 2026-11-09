import AVFoundation
import Observation
import Speech

// 사용자의 답변을 일본어로 받아쓴다. 음성은 저장하지 않는다
@MainActor
@Observable
final class SpeechRecognizer {
  private(set) var transcript = ""
  private(set) var isListening = false
  // 마이크 소리 크기(0~1). 듣는 동안 목소리 막대에 쓴다
  private(set) var level: Float = 0

  @ObservationIgnored private let recognizer = SFSpeechRecognizer(
    locale: Locale(identifier: "ja-JP"))
  @ObservationIgnored private let audioEngine = AVAudioEngine()
  @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
  @ObservationIgnored private var task: SFSpeechRecognitionTask?
  @ObservationIgnored private var committed = ""
  @ObservationIgnored private var partial = ""

  var isAvailable: Bool { recognizer?.isAvailable ?? false }

  // 권한 응답과 오디오 콜백은 메인 스레드가 아닌 곳에서 오므로 nonisolated로 둔다
  nonisolated static func requestAuthorization() async -> Bool {
    let speech = await withCheckedContinuation {
      (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
      SFSpeechRecognizer.requestAuthorization(Self.resumer(continuation))
    }
    guard speech == .authorized else { return false }
    return await AVAudioApplication.requestRecordPermission()
  }

  nonisolated private static func resumer(
    _ continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>
  ) -> @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void {
    { continuation.resume(returning: $0) }
  }

  nonisolated private static func tapBlock(
    for request: SFSpeechAudioBufferRecognitionRequest, owner: SpeechRecognizer
  ) -> AVAudioNodeTapBlock {
    nonisolated(unsafe) let target = request
    return { [weak owner] buffer, _ in
      target.append(buffer)
      guard let owner else { return }
      let level = Self.level(of: buffer)
      Task { @MainActor in owner.updateLevel(level) }
    }
  }

  nonisolated private static func level(of buffer: AVAudioPCMBuffer) -> Float {
    guard let channel = buffer.floatChannelData?[0] else { return 0 }
    let samples = UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength))
    return AudioLevel.normalized(rms: AudioLevel.rms(samples))
  }

  // 막대가 튀지 않도록 커질 때는 바로, 작아질 때는 천천히 따라간다
  private func updateLevel(_ value: Float) {
    guard isListening else { return }
    level = value > level ? value : level * 0.6 + value * 0.4
  }

  func reset() {
    committed = ""
    partial = ""
    transcript = ""
  }

  func start() throws {
    guard !isListening, let recognizer, recognizer.isAvailable else {
      throw SpeechRecognizerError.unavailable
    }
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    if recognizer.supportsOnDeviceRecognition {
      request.requiresOnDeviceRecognition = true
    }
    self.request = request

    let input = audioEngine.inputNode
    input.removeTap(onBus: 0)
    input.installTap(
      onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0),
      block: Self.tapBlock(for: request, owner: self))
    audioEngine.prepare()
    try audioEngine.start()
    isListening = true
    startTask(recognizer: recognizer, request: request)
  }

  // 받아쓴 내용은 남긴다. 다시 start()하면 이어서 붙인다
  func stop() {
    guard isListening else { return }
    isListening = false
    level = 0
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    request?.endAudio()
    task?.cancel()
    commitPartial()
    request = nil
    task = nil
  }

  private func startTask(
    recognizer: SFSpeechRecognizer, request: SFSpeechAudioBufferRecognitionRequest
  ) {
    task = recognizer.recognitionTask(
      with: request, resultHandler: Self.resultHandler(for: self, request: request))
  }

  nonisolated private static func resultHandler(
    for owner: SpeechRecognizer, request: SFSpeechAudioBufferRecognitionRequest
  ) -> @Sendable (SFSpeechRecognitionResult?, Error?) -> Void {
    nonisolated(unsafe) let source = request
    return { [weak owner] result, error in
      let text = result?.bestTranscription.formattedString
      let isFinal = result?.isFinal ?? false
      let failed = error != nil
      Task { @MainActor in
        owner?.handle(text: text, isFinal: isFinal, failed: failed, for: source)
      }
    }
  }

  private func handle(
    text: String?, isFinal: Bool, failed: Bool, for source: SFSpeechAudioBufferRecognitionRequest
  ) {
    guard source === request else { return }
    if let text {
      partial = text
      transcript = Self.join(committed, partial)
    }
    // 한 번의 인식은 약 1분에서 끝나므로, 듣는 중이면 새 인식을 이어 붙인다
    if (isFinal || failed) && isListening, let recognizer {
      commitPartial()
      let next = SFSpeechAudioBufferRecognitionRequest()
      next.shouldReportPartialResults = true
      next.requiresOnDeviceRecognition = source.requiresOnDeviceRecognition
      request = next
      let input = audioEngine.inputNode
      input.removeTap(onBus: 0)
      input.installTap(
        onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0),
        block: Self.tapBlock(for: next, owner: self))
      startTask(recognizer: recognizer, request: next)
    }
  }

  private func commitPartial() {
    committed = Self.join(committed, partial)
    partial = ""
    transcript = committed
  }

  private static func join(_ a: String, _ b: String) -> String {
    if a.isEmpty { return b }
    if b.isEmpty { return a }
    return a + b
  }
}

enum SpeechRecognizerError: Error {
  case unavailable
}
