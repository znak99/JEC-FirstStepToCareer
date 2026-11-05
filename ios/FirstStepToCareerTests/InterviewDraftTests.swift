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
