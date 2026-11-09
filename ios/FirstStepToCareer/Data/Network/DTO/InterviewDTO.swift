import Foundation

// 면접 API가 주고받는 JSON 그대로의 형식 (ARCHITECTURE.md 5절). 앱 안에서는 Domain 형식으로 바꿔 쓴다.
// 문자열 값을 그대로 쓰는 Domain 열거형은 여기서 JSON으로 읽고 쓸 수 있게 한다
extension InterviewType: Codable {}
extension HiringType: Codable {}
extension InterviewStatus: Codable {}

struct DeductionCountsDTO: Codable, Equatable {
  let minor: Int
  let moderate: Int
  let major: Int
  let outside: Int

  init(_ value: DeductionCounts) {
    minor = value.minor
    moderate = value.moderate
    major = value.major
    outside = value.outside
  }

  var domain: DeductionCounts {
    DeductionCounts(minor: minor, moderate: moderate, major: major, outside: outside)
  }
}

struct InterviewScoresDTO: Codable, Equatable {
  let total: Double?
  let structure: Double?
  let logic: Double?
  let gaze: Double?
  let head: Double?

  var domain: InterviewScores {
    InterviewScores(total: total, structure: structure, logic: logic, gaze: gaze, head: head)
  }
}

struct QuestionScoresDTO: Codable, Equatable {
  let structure: Double
  let logic: Double
  let gaze: Double?
  let head: Double?

  var domain: QuestionScores {
    QuestionScores(structure: structure, logic: logic, gaze: gaze, head: head)
  }
}

struct AnswerDTO: Codable, Equatable {
  let transcript: String
  let durationMs: Int
  let gaze: DeductionCountsDTO?
  let head: DeductionCountsDTO?

  var domain: Answer {
    Answer(transcript: transcript, durationMs: durationMs, gaze: gaze?.domain, head: head?.domain)
  }
}

struct QuestionDTO: Codable, Equatable {
  let id: String
  let position: Int
  let preface: String?
  let text: String
  let answer: AnswerDTO?
  let scores: QuestionScoresDTO?

  var domain: Question {
    Question(
      id: id, position: position, preface: preface, text: text, answer: answer?.domain,
      scores: scores?.domain)
  }
}

struct InterviewDetailDTO: Codable, Equatable {
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
  let scores: InterviewScoresDTO?
  let feedback: String?
  let closingMessage: String?
  let questions: [QuestionDTO]

  var domain: InterviewDetail {
    InterviewDetail(
      id: id, companyName: companyName, industry: industry, jobTitle: jobTitle,
      interviewType: interviewType, hiringType: hiringType, questionCount: questionCount,
      faceTracking: faceTracking, status: status, startedAt: startedAt, completedAt: completedAt,
      scores: scores?.domain, feedback: feedback, closingMessage: closingMessage,
      questions: questions.map(\.domain))
  }
}

struct InterviewSummaryDTO: Codable, Equatable {
  let id: String
  let companyName: String
  let industry: String
  let jobTitle: String
  let interviewType: InterviewType
  let hiringType: HiringType
  let status: InterviewStatus
  let startedAt: String
  let completedAt: String?
  let scores: InterviewScoresDTO?

  var domain: InterviewSummary {
    InterviewSummary(
      id: id, companyName: companyName, industry: industry, jobTitle: jobTitle,
      interviewType: interviewType, hiringType: hiringType, status: status, startedAt: startedAt,
      completedAt: completedAt, scores: scores?.domain)
  }
}

// 면접 기록 목록의 한 페이지. 다음 페이지가 없으면 nextCursor가 nil
struct InterviewPageDTO: Codable, Equatable {
  let items: [InterviewSummaryDTO]
  let nextCursor: String?
}

struct NewInterviewDTO: Codable, Equatable {
  let companyName: String
  let industry: String
  let jobTitle: String
  let interviewType: InterviewType
  let hiringType: HiringType
  let questionCount: Int
  let faceTracking: Bool

  init(_ value: NewInterview) {
    companyName = value.companyName
    industry = value.industry
    jobTitle = value.jobTitle
    interviewType = value.interviewType
    hiringType = value.hiringType
    questionCount = value.questionCount
    faceTracking = value.faceTracking
  }
}

struct AnswerSubmissionDTO: Codable, Equatable {
  let transcript: String
  let durationMs: Int
  let gaze: DeductionCountsDTO?
  let head: DeductionCountsDTO?

  init(_ value: AnswerSubmission) {
    transcript = value.transcript
    durationMs = value.durationMs
    gaze = value.gaze.map(DeductionCountsDTO.init)
    head = value.head.map(DeductionCountsDTO.init)
  }

  // 측정하지 않을 때도 키를 null로 보내야 한다(서버가 키 누락을 거절한다)
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(transcript, forKey: .transcript)
    try container.encode(durationMs, forKey: .durationMs)
    try container.encode(gaze, forKey: .gaze)
    try container.encode(head, forKey: .head)
  }
}

struct AnswerResultDTO: Codable, Equatable {
  let status: InterviewStatus
  let nextQuestion: QuestionDTO?
  let closingMessage: String?

  var domain: AnswerResult {
    AnswerResult(status: status, nextQuestion: nextQuestion?.domain, closingMessage: closingMessage)
  }
}

struct ServiceStatusDTO: Codable, Equatable {
  let aiEnabled: Bool

  var domain: ServiceStatus { ServiceStatus(aiEnabled: aiEnabled) }
}
