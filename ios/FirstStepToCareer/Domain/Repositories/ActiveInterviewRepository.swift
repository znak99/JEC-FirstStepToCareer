import Foundation

// 이 iPhone에서 시작했지만 아직 끝나지 않은 면접의 ID. 앱이 도중에 꺼지면 다음 실행 때 이 면접을 지운다
protocol ActiveInterviewRepository: Sendable {
  var interviewId: String? { get }
  func save(_ id: String)
  func clear()
}
