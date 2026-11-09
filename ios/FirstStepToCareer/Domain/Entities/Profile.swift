import Foundation

// 온보딩에서 입력하는 사용자 정보. 닉네임만 필수다
struct Profile: Hashable, Sendable {
  static let nicknameLimit = 20
  static let choiceLimit = InterviewDraft.choiceLimit

  var nickname: String
  var hiringType: HiringType?
  var industry: String?
  var jobTitle: String?

  // 앞뒤 공백을 지우고 만든다. 닉네임이 비었거나 어느 항목이든 글자 수를 넘으면 만들지 않는다
  // 서버나 이 iPhone에 이미 저장된 값을 그대로 옮길 때 쓴다. 다시 검사하지 않는다
  init(saved nickname: String, hiringType: HiringType?, industry: String?, jobTitle: String?) {
    self.nickname = nickname
    self.hiringType = hiringType
    self.industry = industry
    self.jobTitle = jobTitle
  }

  init?(nickname: String, hiringType: HiringType?, industry: String, jobTitle: String) {
    guard let nickname = Self.trimmed(nickname),
      Self.fits(nickname, limit: Self.nicknameLimit),
      Self.fits(industry, limit: Self.choiceLimit),
      Self.fits(jobTitle, limit: Self.choiceLimit)
    else { return nil }
    self.nickname = nickname
    self.hiringType = hiringType
    self.industry = Self.trimmed(industry)
    self.jobTitle = Self.trimmed(jobTitle)
  }

  // 공백만 있으면 입력하지 않은 것으로 본다
  static func trimmed(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  static func fits(_ value: String, limit: Int) -> Bool {
    (trimmed(value)?.count ?? 0) <= limit
  }
}
