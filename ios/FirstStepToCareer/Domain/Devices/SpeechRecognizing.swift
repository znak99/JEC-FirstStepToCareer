import Foundation

// 사용자의 답변을 일본어로 받아쓴다. 음성은 저장하지 않는다
@MainActor
protocol SpeechRecognizing: AnyObject {
  var transcript: String { get }
  var isListening: Bool { get }
  // 마이크 소리 크기(0~1). 목소리 막대에 쓴다
  var level: Float { get }
  // 지금 일본어 음성 인식을 쓸 수 있는지
  var isAvailable: Bool { get }
  // 받아쓴 글을 비운다
  func reset()
  // 이어서 듣는다. 앞서 받아쓴 글은 남긴다
  func start() throws
  func stop()
}
