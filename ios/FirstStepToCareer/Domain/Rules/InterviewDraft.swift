import Foundation

// 면접 홈에서 입력한 값. 면접 준비 화면을 거쳐 서버에 보낸다
struct InterviewDraft: Hashable, Sendable {
  static let companyNameLimit = 100
  static let choiceLimit = 50
  // 질문 수. 서버가 받는 범위(ARCHITECTURE.md 5절)와 처음 고른 값
  static let questionCountRange = 3...7
  static let defaultQuestionCount = 5

  var companyName = ""
  var industry = ""
  var jobTitle = ""
  var interviewType = InterviewType.hr
  var hiringType = HiringType.newGrad
  var questionCount = Self.defaultQuestionCount

  var isValid: Bool {
    Self.isFilled(companyName, limit: Self.companyNameLimit)
      && Self.isFilled(industry, limit: Self.choiceLimit)
      && Self.isFilled(jobTitle, limit: Self.choiceLimit)
      && Self.questionCountRange.contains(questionCount)
  }

  func request(faceTracking: Bool) -> NewInterview {
    NewInterview(
      companyName: companyName.trimmingCharacters(in: .whitespacesAndNewlines),
      industry: industry.trimmingCharacters(in: .whitespacesAndNewlines),
      jobTitle: jobTitle.trimmingCharacters(in: .whitespacesAndNewlines),
      interviewType: interviewType,
      hiringType: hiringType,
      questionCount: questionCount,
      faceTracking: faceTracking)
  }

  private static func isFilled(_ value: String, limit: Int) -> Bool {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmed.isEmpty && trimmed.count <= limit
  }
}

extension InterviewType {
  var label: String {
    switch self {
    case .hr: String(localized: "人事面接")
    case .job: String(localized: "職務面接")
    }
  }
}

extension HiringType {
  var label: String {
    switch self {
    case .newGrad: String(localized: "新卒")
    case .midCareer: String(localized: "中途")
    }
  }
}
