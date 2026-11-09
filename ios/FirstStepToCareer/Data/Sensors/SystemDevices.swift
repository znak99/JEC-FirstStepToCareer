import Foundation

// 실제 기기 부품이 Domain의 기기 약속을 따르게 한다
extension FaceTracker: FaceTracking {}
extension FrontCamera: FrontCameraCapturing {}
extension SpeechRecognizer: SpeechRecognizing {}
extension SpeechSynthesizer: SpeechSynthesizing {}

struct SystemAudioSession: AudioSessionControlling {
  func activate() throws { try AudioSessionConfigurator.activate() }
  func deactivate() { AudioSessionConfigurator.deactivate() }
}

struct SystemDeviceCapabilities: DeviceCapabilities {
  var hasFrontCamera: Bool { FrontCamera.isAvailable }
  var hasJapaneseVoice: Bool { SpeechSynthesizer.isAvailable }
  func requestCameraAccess() async -> Bool { await FaceTracker.requestCameraAccess() }
  func requestSpeechAccess() async -> Bool { await SpeechRecognizer.requestAuthorization() }
}
