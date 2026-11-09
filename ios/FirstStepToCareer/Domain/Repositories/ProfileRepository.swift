import Foundation

// 서버에 저장하는 프로필과 약관 동의 기록
protocol ProfileRepository: Sendable {
  // 저장한 적이 없으면 nil
  func fetch() async throws -> Profile?
  // 서버가 정리해 저장한 값을 돌려준다
  func save(_ profile: Profile) async throws -> Profile?
  func recordConsents(to documents: [LegalDocument]) async throws
}
