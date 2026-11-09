import Foundation

// Apple 로그인 때마다 새로 만드는 일회용 무작위 값. Apple에는 해시를, 서버에는 원문을 보낸다
protocol SignInNonceGenerating: Sendable {
  func make() -> String
  func sha256Hex(_ value: String) -> String
}
