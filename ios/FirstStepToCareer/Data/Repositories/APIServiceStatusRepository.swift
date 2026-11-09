import Foundation

// ServiceStatusRepository를 서버 API로 채운다
struct APIServiceStatusRepository: ServiceStatusRepository {
  let api: APIClient

  func isAIEnabled() async throws -> Bool {
    try await api.status().aiEnabled
  }
}
