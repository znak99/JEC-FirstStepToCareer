import Foundation

// 프로필 입력 화면의 값. 업계·직종은 목록에서 고른 값과 「その他」에 직접 입력한 값을 따로 둔다
struct ProfileDraft: Equatable, Sendable {
  static let other = "その他"

  var nickname = ""
  var hiringType: HiringType?
  var industryChoice = ""
  var otherIndustry = ""
  var jobChoice = ""
  var otherJob = ""

  init() {}

  init(_ profile: Profile) {
    nickname = profile.nickname
    hiringType = profile.hiringType
    (industryChoice, otherIndustry) = Self.split(profile.industry, in: ChoiceCatalog.industries)
    (jobChoice, otherJob) = Self.split(profile.jobTitle, in: ChoiceCatalog.jobTitles)
  }

  var industry: String { industryChoice == Self.other ? otherIndustry : industryChoice }
  var jobTitle: String { jobChoice == Self.other ? otherJob : jobChoice }

  // 닉네임이 없거나 글자 수를 넘으면 nil
  var profile: Profile? {
    Profile(nickname: nickname, hiringType: hiringType, industry: industry, jobTitle: jobTitle)
  }

  // 목록에 있는 값이면 그대로 고르고, 없으면 「その他」에 직접 입력한 값으로 본다
  static func split(_ value: String?, in categories: [ChoiceCategory]) -> (
    choice: String, other: String
  ) {
    guard let value, !value.isEmpty else { return ("", "") }
    return ChoiceCatalog.category(containing: value, in: categories) == nil
      ? (other, value) : (value, "")
  }
}
