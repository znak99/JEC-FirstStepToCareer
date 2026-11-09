import Foundation

// InterviewRepository를 서버 API로 채운다
struct APIInterviewRepository: InterviewRepository {
  let api: APIClient

  func create(_ interview: NewInterview) async throws -> InterviewDetail {
    try await api.createInterview(interview)
  }

  func detail(id: String) async throws -> InterviewDetail {
    try await api.interview(id: id)
  }

  func all() async throws -> [InterviewSummary] {
    try await api.allInterviews()
  }

  func delete(id: String) async throws {
    try await api.deleteInterview(id: id)
  }

  func submitAnswer(_ answer: AnswerSubmission, interviewId: String, questionId: String)
    async throws -> AnswerResult
  {
    try await api.submitAnswer(interviewId: interviewId, questionId: questionId, answer)
  }

  func evaluate(id: String) async throws -> InterviewDetail {
    try await api.evaluate(interviewId: id)
  }
}
