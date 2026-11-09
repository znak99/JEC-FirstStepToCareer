import AVFoundation

// 질문을 일본어 음성으로 읽는다
@MainActor
final class SpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate {
  private let synthesizer = AVSpeechSynthesizer()
  private var continuation: CheckedContinuation<Void, Never>?

  static var japaneseVoice: AVSpeechSynthesisVoice? { AVSpeechSynthesisVoice(language: "ja-JP") }
  static var isAvailable: Bool { japaneseVoice != nil }

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  func speak(_ text: String) async {
    stop()
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = Self.japaneseVoice
    await withCheckedContinuation { continuation in
      self.continuation = continuation
      synthesizer.speak(utterance)
    }
  }

  func stop() {
    if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    finish()
  }

  private func finish() {
    continuation?.resume()
    continuation = nil
  }

  nonisolated func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance
  ) {
    Task { @MainActor in self.finish() }
  }

  nonisolated func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance
  ) {
    Task { @MainActor in self.finish() }
  }
}
