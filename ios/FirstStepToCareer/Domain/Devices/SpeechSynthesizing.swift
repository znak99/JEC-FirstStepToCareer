import Foundation

// 질문을 일본어로 읽어 준다
@MainActor
protocol SpeechSynthesizing: AnyObject {
  // 다 읽거나 멈추면 끝난다
  func speak(_ text: String) async
  func stop()
}
