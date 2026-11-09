import Foundation

enum InterviewType: String, CaseIterable, Sendable {
  case hr
  case job
}

enum HiringType: String, CaseIterable, Sendable {
  case newGrad = "new_grad"
  case midCareer = "mid_career"
}

enum InterviewStatus: String, Sendable {
  case inProgress = "in_progress"
  case awaitingEvaluation = "awaiting_evaluation"
  case completed
}

struct DeductionCounts: Equatable, Sendable {
  var minor = 0
  var moderate = 0
  var major = 0
  var outside = 0
}

struct InterviewScores: Equatable, Sendable {
  let total: Double?
  let structure: Double?
  let logic: Double?
  let gaze: Double?
  let head: Double?
}

struct QuestionScores: Equatable, Sendable {
  let structure: Double
  let logic: Double
  let gaze: Double?
  let head: Double?
}

struct Answer: Equatable, Sendable {
  let transcript: String
  let durationMs: Int
  let gaze: DeductionCounts?
  let head: DeductionCounts?
}

struct Question: Equatable, Identifiable, Sendable {
  let id: String
  let position: Int
  let preface: String?
  let text: String
  var answer: Answer? = nil
  var scores: QuestionScores? = nil
}

struct InterviewDetail: Equatable, Identifiable, Sendable {
  let id: String
  let companyName: String
  let industry: String
  let jobTitle: String
  let interviewType: InterviewType
  let hiringType: HiringType
  let questionCount: Int
  let faceTracking: Bool
  let status: InterviewStatus
  let startedAt: String
  let completedAt: String?
  let scores: InterviewScores?
  let feedback: String?
  let closingMessage: String?
  let questions: [Question]
}

extension InterviewDetail {
  // 답변을 모두 마쳤지만 아직 평가하지 않았다
  var needsEvaluation: Bool { status == .awaitingEvaluation }
}

struct InterviewSummary: Equatable, Identifiable, Sendable {
  let id: String
  let companyName: String
  let industry: String
  let jobTitle: String
  let interviewType: InterviewType
  let hiringType: HiringType
  let status: InterviewStatus
  let startedAt: String
  let completedAt: String?
  let scores: InterviewScores?
}

struct NewInterview: Equatable, Sendable {
  var companyName: String
  var industry: String
  var jobTitle: String
  var interviewType: InterviewType
  var hiringType: HiringType
  var questionCount: Int
  var faceTracking: Bool
}

struct AnswerSubmission: Equatable, Sendable {
  let transcript: String
  let durationMs: Int
  let gaze: DeductionCounts?
  let head: DeductionCounts?
}

struct AnswerResult: Equatable, Sendable {
  let status: InterviewStatus
  let nextQuestion: Question?
  let closingMessage: String?
}

struct ServiceStatus: Sendable {
  let aiEnabled: Bool
}
