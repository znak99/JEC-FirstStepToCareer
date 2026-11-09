import Foundation
import Observation

@MainActor
@Observable
final class HistoryModel {
  private(set) var interviews: [CompletedInterview] = []
  private(set) var hasLoaded = false
  private(set) var isLoading = false
  private(set) var loadFailed = false

  private let api: APIClient

  init(api: APIClient) {
    self.api = api
  }

  var summary: HistorySummary { HistorySummary(interviews: interviews) }

  // 모든 페이지를 받아 평가가 끝난 면접만 남긴다. 실패하면 이전에 받은 기록을 그대로 둔다
  func load() async {
    guard !isLoading else { return }
    isLoading = true
    defer { isLoading = false }
    do {
      interviews = CompletedInterview.list(from: try await api.allInterviews())
      loadFailed = false
      hasLoaded = true
    } catch {
      // 탭을 떠나 작업이 취소된 경우는 실패로 보지 않는다
      if !Task.isCancelled { loadFailed = true }
    }
  }
}
