import Foundation

// 이 iPhone에 두는 프로필 사본. 서버에서 받지 못할 때와 화면을 바로 채울 때 쓴다
protocol ProfileCacheRepository: Sendable {
  var profile: Profile? { get }
  func save(_ profile: Profile)
  func clear()
}
