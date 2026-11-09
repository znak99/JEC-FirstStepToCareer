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
  private let loadInterview: LoadInterviewUseCase
  private let evaluateInterview: EvaluateInterviewUseCase
  private let deleteInterview: DeleteInterviewUseCase

  init(
    interviewId: String, loadInterview: LoadInterviewUseCase,
    evaluateInterview: EvaluateInterviewUseCase, deleteInterview: DeleteInterviewUseCase
  ) {
    self.interviewId = interviewId
    self.loadInterview = loadInterview
    self.evaluateInterview = evaluateInterview
    self.deleteInterview = deleteInterview
  }

  // 평가 대기 상태면 평가를 요청한 뒤 결과를 보여 준다
  func load() async {
    state = .loading
    do {
      var detail = try await loadInterview.execute(id: interviewId)
      if detail.needsEvaluation {
        state = .evaluating
        detail = try await evaluateInterview.execute(id: interviewId)
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
      interviewId: interviewId, loadInterview: useCases.loadInterview,
      evaluateInterview: useCases.evaluateInterview, deleteInterview: useCases.deleteInterview)
  }
}
