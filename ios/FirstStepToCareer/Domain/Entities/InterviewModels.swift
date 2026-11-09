import Foundation

enum InterviewType: String, Codable, CaseIterable, Sendable {
  case hr
  case job
}

enum HiringType: String, Codable, CaseIterable, Sendable {
  case newGrad = "new_grad"
  case midCareer = "mid_career"
}

enum InterviewStatus: String, Codable, Sendable {
  case inProgress = "in_progress"
  case awaitingEvaluation = "awaiting_evaluation"
  case completed
}

struct DeductionCounts: Codable, Equatable, Sendable {
  var minor = 0
  var moderate = 0
  var major = 0
  var outside = 0
}

struct InterviewScores: Codable, Equatable, Sendable {
  let total: Double?
  let structure: Double?
  let logic: Double?
  let gaze: Double?
  let head: Double?
}

struct QuestionScores: Codable, Equatable, Sendable {
  let structure: Double
  let logic: Double
  let gaze: Double?
  let head: Double?
}

struct Answer: Codable, Equatable, Sendable {
  let transcript: String
  let durationMs: Int
  let gaze: DeductionCounts?
  let head: DeductionCounts?
}

struct Question: Codable, Equatable, Identifiable, Sendable {
  let id: String
  let position: Int
  let preface: String?
  let text: String
  var answer: Answer? = nil
  var scores: QuestionScores? = nil
}

struct InterviewDetail: Codable, Equatable, Identifiable, Sendable {
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

struct InterviewSummary: Codable, Equatable, Identifiable, Sendable {
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

struct InterviewPage: Codable, Sendable {
  let items: [InterviewSummary]
  let nextCursor: String?
}

struct NewInterview: Codable, Equatable, Sendable {
  var companyName: String
  var industry: String
  var jobTitle: String
  var interviewType: InterviewType
  var hiringType: HiringType
  var questionCount: Int
  var faceTracking: Bool
}

struct AnswerSubmission: Codable, Equatable, Sendable {
  let transcript: String
  let durationMs: Int
  let gaze: DeductionCounts?
  let head: DeductionCounts?

  // 측정하지 않을 때도 키를 null로 보내야 한다(서버가 키 누락을 거절한다)
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(transcript, forKey: .transcript)
    try container.encode(durationMs, forKey: .durationMs)
    try container.encode(gaze, forKey: .gaze)
    try container.encode(head, forKey: .head)
  }
}

struct AnswerResult: Codable, Equatable, Sendable {
  let status: InterviewStatus
  let nextQuestion: Question?
  let closingMessage: String?
}

struct ServiceStatus: Codable, Sendable {
  let aiEnabled: Bool
}
