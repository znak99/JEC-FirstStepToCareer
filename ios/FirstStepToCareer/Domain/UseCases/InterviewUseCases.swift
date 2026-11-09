import Foundation

// 모의면접 (ARCHITECTURE.md 6.1)

struct GetQuestionCountUseCase: Sendable {
  let settings: any AppSettingsRepository

  func execute() -> Int { settings.questionCount }
}

// 마지막으로 고른 질문 수로 다음에도 시작한다
struct SaveQuestionCountUseCase: Sendable {
  let settings: any AppSettingsRepository

  func execute(_ count: Int) { settings.setQuestionCount(count) }
}

// 3초간 응시하는 동안 모은 얼굴 방향으로 시선·머리의 기준점을 만든다. 인식이 불안정하면 nil
struct CalibrateFaceUseCase: Sendable {
  static let seconds: TimeInterval = 3

  @MainActor
  func execute(with tracker: any FaceTracking) async -> FaceBaseline? {
    FaceBaseline.make(from: await tracker.collectSamples(duration: Self.seconds))
  }
}

// 면접을 만들고, 앱이 도중에 꺼지면 지울 수 있게 ID를 이 iPhone에 적어 둔다
struct StartInterviewUseCase: Sendable {
  let interviews: any InterviewRepository
  let activeInterview: any ActiveInterviewRepository

  func execute(_ draft: InterviewDraft, faceTracking: Bool) async throws -> InterviewDetail {
    let interview = try await interviews.create(draft.request(faceTracking: faceTracking))
    activeInterview.save(interview.id)
    return interview
  }
}

// 답변을 보내고 맞장구와 다음 질문을 받는다. 마지막 답변이 저장되면 평가 대기가 되므로
// 다음 실행 때 지우지 않게 ID를 지운다
struct SubmitAnswerUseCase: Sendable {
  let interviews: any InterviewRepository
  let activeInterview: any ActiveInterviewRepository

  func execute(_ answer: AnswerSubmission, interviewId: String, questionId: String) async throws
    -> AnswerResult
  {
    let result = try await interviews.submitAnswer(
      answer, interviewId: interviewId, questionId: questionId)
    if result.nextQuestion == nil { activeInterview.clear() }
    return result
  }
}

// 그만두면 면접을 지운다. 지우지 못하면 ID를 남겨 다음 실행 때 다시 지운다
struct QuitInterviewUseCase: Sendable {
  let interviews: any InterviewRepository
  let activeInterview: any ActiveInterviewRepository

  func execute(interviewId: String) async {
    if (try? await interviews.delete(id: interviewId)) != nil {
      activeInterview.clear()
    }
  }
}

// 면접 결과. 평가 대기면 평가를 요청한 뒤 돌려준다. 평가를 시작할 때 onEvaluating을 부른다
struct LoadInterviewResultUseCase: Sendable {
  let interviews: any InterviewRepository

  func execute(id: String, onEvaluating: @MainActor () -> Void) async throws -> InterviewDetail {
    let detail = try await interviews.detail(id: id)
    guard detail.status == .awaitingEvaluation else { return detail }
    await onEvaluating()
    return try await interviews.evaluate(id: id)
  }
}

struct DeleteInterviewUseCase: Sendable {
  let interviews: any InterviewRepository

  func execute(id: String) async throws { try await interviews.delete(id: id) }
}

// 모든 기록을 받아 평가가 끝난 면접만 남긴다
struct LoadCompletedInterviewsUseCase: Sendable {
  let interviews: any InterviewRepository

  func execute() async throws -> [CompletedInterview] {
    CompletedInterview.list(from: try await interviews.all())
  }
}
