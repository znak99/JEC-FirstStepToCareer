import Foundation

// 면접을 만들고, 답변을 보내고, 평가받고, 읽고, 지운다. 실제로는 서버에 묻는다
protocol InterviewRepository: Sendable {
  func create(_ interview: NewInterview) async throws -> InterviewDetail
  func detail(id: String) async throws -> InterviewDetail
  // 모든 기록. 최신순
  func all() async throws -> [InterviewSummary]
  func delete(id: String) async throws
  // 맞장구와 다음 질문, 또는 마지막이면 마무리 인사를 돌려준다
  func submitAnswer(_ answer: AnswerSubmission, interviewId: String, questionId: String)
    async throws -> AnswerResult
  func evaluate(id: String) async throws -> InterviewDetail
}
