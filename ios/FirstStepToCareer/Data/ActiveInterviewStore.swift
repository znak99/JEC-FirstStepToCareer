import Foundation

// 이 iPhone에서 시작했지만 아직 끝나지 않은 면접의 ID. 앱이 도중에 꺼지면 다음 실행 때 이 면접을 지운다
// UserDefaults는 여러 스레드에서 써도 안전하다고 Apple 문서에 적혀 있다
struct ActiveInterviewStore: @unchecked Sendable {
  private static let key = "activeInterviewId"
  let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  var interviewId: String? {
    defaults.string(forKey: Self.key)
  }

  func save(_ id: String) {
    defaults.set(id, forKey: Self.key)
  }

  func clear() {
    defaults.removeObject(forKey: Self.key)
  }
}
