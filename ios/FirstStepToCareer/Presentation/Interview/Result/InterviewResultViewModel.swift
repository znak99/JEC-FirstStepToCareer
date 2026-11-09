import Foundation
import Observation

@MainActor
@Observable
final class InterviewResultViewModel {
  enum State: Equatable {
    case loading
    case evaluating
    case loaded(InterviewDetail)
    case failed(String)
  }

  let interviewId: String
  private(set) var state = State.loading
  private let api: APIClient

  init(interviewId: String, api: APIClient) {
    self.interviewId = interviewId
    self.api = api
  }

  // 평가 대기 상태면 평가를 요청한 뒤 결과를 보여 준다
  func load() async {
    state = .loading
    do {
      var detail = try await api.interview(id: interviewId)
      if detail.status == .awaitingEvaluation {
        state = .evaluating
        detail = try await api.evaluate(interviewId: interviewId)
      }
      state = .loaded(detail)
    } catch {
      state = .failed(ErrorMessage.text(for: error))
    }
  }

  func delete() async -> Bool {
    do {
      try await api.deleteInterview(id: interviewId)
      return true
    } catch {
      state = .failed(String(localized: "削除できませんでした。もう一度お試しください。"))
      return false
    }
  }
}
