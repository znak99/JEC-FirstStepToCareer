import Foundation

// 이 iPhone이 면접에 쓰는 기능을 갖췄는지와 사용 허락
@MainActor
protocol DeviceCapabilities {
  var hasFrontCamera: Bool { get }
  var hasJapaneseVoice: Bool { get }
  // 이미 허락했으면 바로 true, 처음이면 사용자에게 묻는다
  func requestCameraAccess() async -> Bool
  // 음성 인식과 마이크를 모두 허락받으면 true
  func requestSpeechAccess() async -> Bool
}
