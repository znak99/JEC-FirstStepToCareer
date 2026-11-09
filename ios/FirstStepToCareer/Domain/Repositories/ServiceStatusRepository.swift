import Foundation

// 개발자가 켜고 끄는 AI 스위치의 상태
protocol ServiceStatusRepository: Sendable {
  func isAIEnabled() async throws -> Bool
}
