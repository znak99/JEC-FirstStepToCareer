import Foundation

// ProfileRepository를 서버 API로 채운다
struct APIProfileRepository: ProfileRepository {
  let api: APIClient

  func fetch() async throws -> Profile? {
    try await api.profile()
  }

  func save(_ profile: Profile) async throws -> Profile? {
    try await api.saveProfile(profile)
  }

  func recordConsents(to documents: [LegalDocument]) async throws {
    try await api.recordConsents(documents)
  }
}
