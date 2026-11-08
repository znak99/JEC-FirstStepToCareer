import Foundation

// 면접 홈에서 입력하는 값 (SITE_MAP S-01).
// 프로필의 채용 구분·업계·직종으로 미리 채우고, 프로필이 바뀌면 그 세 값만 다시 채운다.
// 회사명과 면접 종류는 면접을 마친 뒤에도 남겨 같은 조건으로 다시 연습할 수 있게 한다
struct InterviewForm: Equatable, Sendable {
  // 회사명을 비워 두면 이 이름으로 면접한다
  static let defaultCompanyName = "株式会社就活一歩"

  var companyName = ""
  var interviewType = InterviewType.hr
  var hiringType = HiringType.newGrad
  var industryChoice = ""
  var otherIndustry = ""
  var jobChoice = ""
  var otherJob = ""
  var questionCount: Int

  // 마지막으로 채운 프로필. 같은 프로필이면 사용자가 이 화면에서 고친 값을 덮어쓰지 않는다
  private(set) var filledProfile: Profile?

  init(profile: Profile?, questionCount: Int) {
    self.questionCount = questionCount
    fill(from: profile)
  }

  // 화면이 다시 보일 때 부른다
  mutating func sync(profile: Profile?) {
    if profile != filledProfile { fill(from: profile) }
  }

  var draft: InterviewDraft {
    let typed = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
    return InterviewDraft(
      companyName: typed.isEmpty ? Self.defaultCompanyName : companyName,
      industry: industryChoice == ProfileDraft.other ? otherIndustry : industryChoice,
      jobTitle: jobChoice == ProfileDraft.other ? otherJob : jobChoice,
      interviewType: interviewType,
      hiringType: hiringType,
      questionCount: questionCount)
  }

  private mutating func fill(from profile: Profile?) {
    filledProfile = profile
    hiringType = profile?.hiringType ?? .newGrad
    let filled = profile.map(ProfileDraft.init) ?? ProfileDraft()
    industryChoice = filled.industryChoice
    otherIndustry = filled.otherIndustry
    jobChoice = filled.jobChoice
    otherJob = filled.otherJob
  }
}
