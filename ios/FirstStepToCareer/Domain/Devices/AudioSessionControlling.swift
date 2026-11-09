import Foundation

// 면접하는 동안 소리 내기와 듣기를 함께 쓰도록 오디오를 준비하고 정리한다
protocol AudioSessionControlling: Sendable {
  func activate() throws
  func deactivate()
}
