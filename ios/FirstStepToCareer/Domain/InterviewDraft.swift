import Foundation

// 면접 홈에서 입력한 값. 면접 준비 화면을 거쳐 서버에 보낸다
struct InterviewDraft: Hashable, Sendable {
  static let companyNameLimit = 100
  static let choiceLimit = 50

  var companyName = ""
  var industry = ""
  var jobTitle = ""
  var interviewType = InterviewType.hr
  var hiringType = HiringType.newGrad
  var questionCount = AppSettings.defaultQuestionCount

  var isValid: Bool {
    Self.isFilled(companyName, limit: Self.companyNameLimit)
      && Self.isFilled(industry, limit: Self.choiceLimit)
      && Self.isFilled(jobTitle, limit: Self.choiceLimit)
      && AppSettings.questionCountRange.contains(questionCount)
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
    case .hr: "人事面接"
    case .job: "職務面接"
    }
  }
}

extension HiringType {
  var label: String {
    switch self {
    case .newGrad: "新卒"
    case .midCareer: "中途"
    }
  }
}
