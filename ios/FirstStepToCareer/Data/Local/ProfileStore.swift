import Foundation

// 온보딩에서 입력한 정보. 서버에 저장하기 전까지는 이 iPhone에만 둔다
// UserDefaults는 여러 스레드에서 써도 안전하다고 Apple 문서에 적혀 있다
struct ProfileStore: @unchecked Sendable {
  private static let key = "profile"
  let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  var profile: Profile? {
    defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(Profile.self, from: $0) }
  }

  func save(_ profile: Profile) {
    defaults.set(try? JSONEncoder().encode(profile), forKey: Self.key)
  }

  func clear() {
    defaults.removeObject(forKey: Self.key)
  }
}
