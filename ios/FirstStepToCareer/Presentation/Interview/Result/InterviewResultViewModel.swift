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
  private let loadInterviewResult: LoadInterviewResultUseCase
  private let deleteInterview: DeleteInterviewUseCase

  init(
    interviewId: String, loadInterviewResult: LoadInterviewResultUseCase,
    deleteInterview: DeleteInterviewUseCase
  ) {
    self.interviewId = interviewId
    self.loadInterviewResult = loadInterviewResult
    self.deleteInterview = deleteInterview
  }

  // 평가 대기 상태면 평가를 요청한 뒤 결과를 보여 준다
  func load() async {
    state = .loading
    do {
      let detail = try await loadInterviewResult.execute(id: interviewId) {
        state = .evaluating
      }
      state = .loaded(detail)
    } catch {
      state = .failed(ErrorMessage.text(for: error))
    }
  }

  func delete() async -> Bool {
    do {
      try await deleteInterview.execute(id: interviewId)
      return true
    } catch {
      state = .failed(String(localized: "削除できませんでした。もう一度お試しください。"))
      return false
    }
  }
}

extension InterviewResultViewModel {
  convenience init(interviewId: String, useCases: UseCases) {
    self.init(
      interviewId: interviewId, loadInterviewResult: useCases.loadInterviewResult,
      deleteInterview: useCases.deleteInterview)
  }
}
