import Testing

@testable import FirstStepToCareer

struct InterviewDraftTests {
  private func filled() -> InterviewDraft {
    InterviewDraft(companyName: "A社", industry: "IT", jobTitle: "SE", questionCount: 5)
  }

  @Test func requiresAllFields() {
    #expect(filled().isValid)
    var draft = filled()
    draft.companyName = "   "
    #expect(!draft.isValid)
    draft = filled()
    draft.industry = ""
    #expect(!draft.isValid)
    draft = filled()
    draft.jobTitle = "\n"
    #expect(!draft.isValid)
  }

  @Test(arguments: [(100, true), (101, false)])
  func companyNameLength(length: Int, valid: Bool) {
    var draft = filled()
    draft.companyName = String(repeating: "あ", count: length)
    #expect(draft.isValid == valid)
  }

  @Test(arguments: [(50, true), (51, false)])
  func choiceLength(length: Int, valid: Bool) {
    var draft = filled()
    draft.jobTitle = String(repeating: "a", count: length)
    #expect(draft.isValid == valid)
  }

  @Test(arguments: [(2, false), (3, true), (7, true), (8, false)])
  func questionCountRange(count: Int, valid: Bool) {
    var draft = filled()
    draft.questionCount = count
    #expect(draft.isValid == valid)
  }

  @Test func requestTrimsValues() {
    var draft = filled()
    draft.companyName = "  A社 \n"
    let request = draft.request(faceTracking: false)
    #expect(request.companyName == "A社")
    #expect(request.faceTracking == false)
  }
}

struct InterviewFormTests {
  private func profile(
    hiringType: HiringType? = .midCareer, industry: String = "銀行・信用金庫", jobTitle: String = "宇宙飛行士"
  ) throws -> Profile {
    try #require(
      Profile(nickname: "たろう", hiringType: hiringType, industry: industry, jobTitle: jobTitle))
  }

  @Test func fillsFromProfileAndMapsUnknownValuesToOther() throws {
    let form = InterviewForm(profile: try profile(), questionCount: 5)
    #expect(form.hiringType == .midCareer)
    #expect(form.industryChoice == "銀行・信用金庫")
    #expect(form.jobChoice == ProfileDraft.other)
    #expect(form.otherJob == "宇宙飛行士")
    #expect(form.companyName == "")
    #expect(form.interviewType == .hr)
  }

  @Test func withoutProfileStartsEmptyAsNewGrad() {
    let form = InterviewForm(profile: nil, questionCount: 3)
    #expect(form.hiringType == .newGrad)
    #expect(form.industryChoice == "")
    #expect(form.jobChoice == "")
    #expect(form.questionCount == 3)
    #expect(!form.draft.isValid)
  }

  @Test func draftUsesOtherInputAndQuestionCount() throws {
    var form = InterviewForm(profile: try profile(), questionCount: 5)
    form.companyName = "A社"
    form.questionCount = 7
    let draft = form.draft
    #expect(draft.isValid)
    #expect(draft.companyName == "A社")
    #expect(draft.industry == "銀行・信用金庫")
    #expect(draft.jobTitle == "宇宙飛行士")
    #expect(draft.hiringType == .midCareer)
    #expect(draft.questionCount == 7)
  }

  @Test(arguments: ["", "   ", "\n　"])
  func blankCompanyNameUsesDefault(_ name: String) throws {
    var form = InterviewForm(profile: try profile(), questionCount: 5)
    form.companyName = name
    #expect(form.draft.companyName == InterviewForm.defaultCompanyName)
    #expect(form.draft.isValid)
  }

  @Test func companyNameOverLimitIsInvalid() throws {
    var form = InterviewForm(profile: try profile(), questionCount: 5)
    form.companyName = String(repeating: "社", count: InterviewDraft.companyNameLimit + 1)
    #expect(!form.draft.isValid)
  }

  @Test func syncWithSameProfileKeepsEdits() throws {
    let saved = try profile()
    var form = InterviewForm(profile: saved, questionCount: 5)
    form.companyName = "A社"
    form.interviewType = .job
    form.hiringType = .newGrad
    form.industryChoice = "総合商社"
    form.questionCount = 7
    form.sync(profile: saved)
    #expect(form.hiringType == .newGrad)
    #expect(form.industryChoice == "総合商社")
    #expect(form.companyName == "A社")
    #expect(form.questionCount == 7)
  }

  @Test func syncWithChangedProfileRefillsOnlyProfileFields() throws {
    var form = InterviewForm(profile: try profile(), questionCount: 5)
    form.companyName = "A社"
    form.interviewType = .job
    form.sync(profile: try profile(hiringType: nil, industry: "広告", jobTitle: ""))
    #expect(form.hiringType == .newGrad)
    #expect(form.industryChoice == "広告")
    #expect(form.jobChoice == "")
    #expect(form.otherJob == "")
    #expect(form.companyName == "A社")
    #expect(form.interviewType == .job)
  }
}
