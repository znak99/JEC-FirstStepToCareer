import Foundation
import Testing

@testable import FirstStepToCareer

// 서버 JSON 형식(DTO)과 Domain 형식 사이의 변환
struct DTOMappingTests {
  private static func roundTrip<DTO: Codable>(_ value: DTO) throws -> DTO {
    try JSONDecoder().decode(DTO.self, from: JSONEncoder().encode(value))
  }

  private static func object(_ value: some Encodable) throws -> [String: Any] {
    let data = try JSONEncoder().encode(value)
    return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  private static let measured = DeductionCounts(minor: 6, moderate: 2, major: 1, outside: 0)

  private static let fullDetail = InterviewDetail(
    id: "i", companyName: "株式会社テスト", industry: "商社", jobTitle: "営業", interviewType: .job,
    hiringType: .midCareer, questionCount: 3, faceTracking: true, status: .completed,
    startedAt: "2026-11-06T00:00:00.000Z", completedAt: "2026-11-06T00:10:00.000Z",
    scores: InterviewScores(total: 78.4, structure: 80, logic: 75.5, gaze: 82.3, head: 75.8),
    feedback: "良い", closingMessage: "ありがとうございました",
    questions: [
      Question(
        id: "q1", position: 1, preface: "本日は", text: "自己紹介を",
        answer: Answer(transcript: "はい", durationMs: 52000, gaze: measured, head: measured),
        scores: QuestionScores(structure: 80, logic: 70, gaze: 98.7, head: 99.7)),
      Question(id: "q2", position: 2, preface: nil, text: "志望動機を"),
    ])

  // ARCHITECTURE.md 5절의 면접 상세 예시
  @Test func decodesDocumentedInterviewDetail() throws {
    let json = #"""
      {"id":"i","companyName":"A","industry":"IT","jobTitle":"SE","interviewType":"hr","hiringType":"new_grad","questionCount":4,"faceTracking":true,"status":"completed","startedAt":"2026-11-06T00:00:00.000Z","completedAt":"2026-11-06T00:10:00.000Z","scores":{"total":78.4,"structure":80.0,"logic":75.5,"gaze":82.3,"head":75.8},"feedback":"f","closingMessage":"c","questions":[{"id":"q1","position":1,"preface":"p","text":"t","answer":{"transcript":"a","durationMs":52000,"gaze":{"minor":6,"moderate":2,"major":1,"outside":0},"head":{"minor":3,"moderate":0,"major":0,"outside":0}},"scores":{"structure":80,"logic":70,"gaze":98.7,"head":99.7}}]}
      """#
    let detail = try JSONDecoder().decode(InterviewDetailDTO.self, from: Data(json.utf8)).domain
    #expect(detail.interviewType == .hr)
    #expect(detail.hiringType == .newGrad)
    #expect(detail.status == .completed)
    #expect(detail.scores?.head == 75.8)
    let question = try #require(detail.questions.first)
    #expect(question.answer?.gaze == DeductionCounts(minor: 6, moderate: 2, major: 1, outside: 0))
    #expect(question.answer?.head?.minor == 3)
    #expect(question.scores?.logic == 70)
  }

  @Test func roundTripsInterviewShapes() throws {
    #expect(try Self.roundTrip(InterviewDetailDTO(Self.fullDetail)).domain == Self.fullDetail)
    let unevaluated = InterviewDetail(
      id: "j", companyName: "A", industry: "IT", jobTitle: "SE", interviewType: .hr,
      hiringType: .newGrad, questionCount: 3, faceTracking: false, status: .inProgress,
      startedAt: "2026-11-06T00:00:00.000Z", completedAt: nil, scores: nil, feedback: nil,
      closingMessage: nil, questions: [Question(id: "q1", position: 1, preface: "p", text: "t")])
    #expect(try Self.roundTrip(InterviewDetailDTO(unevaluated)).domain == unevaluated)
    let summary = InterviewSummary(
      id: "s", companyName: "A", industry: "IT", jobTitle: "SE", interviewType: .job,
      hiringType: .midCareer, status: .awaitingEvaluation, startedAt: "2026-11-06T00:00:00.000Z",
      completedAt: nil,
      scores: InterviewScores(total: nil, structure: 1, logic: 2, gaze: nil, head: nil))
    #expect(try Self.roundTrip(InterviewSummaryDTO(summary)).domain == summary)
    let next = AnswerResult(
      status: .inProgress,
      nextQuestion: Question(id: "q2", position: 2, preface: "なるほど", text: "次"),
      closingMessage: nil)
    let closing = AnswerResult(
      status: .awaitingEvaluation, nextQuestion: nil, closingMessage: "以上です")
    #expect(try Self.roundTrip(AnswerResultDTO(next)).domain == next)
    #expect(try Self.roundTrip(AnswerResultDTO(closing)).domain == closing)
  }

  @Test func answerSubmissionSendsNullWhenNotMeasured() throws {
    let unmeasured = try Self.object(
      AnswerSubmissionDTO(AnswerSubmission(transcript: "はい", durationMs: 10, gaze: nil, head: nil)))
    #expect(Set(unmeasured.keys) == ["transcript", "durationMs", "gaze", "head"])
    #expect(unmeasured["gaze"] is NSNull)
    #expect(unmeasured["head"] is NSNull)
    let measured = try Self.object(
      AnswerSubmissionDTO(
        AnswerSubmission(transcript: "はい", durationMs: 10, gaze: Self.measured, head: nil)))
    let gaze = try #require(measured["gaze"] as? [String: Int])
    #expect(gaze == ["minor": 6, "moderate": 2, "major": 1, "outside": 0])
    #expect(measured["head"] is NSNull)
  }

  @Test func newInterviewUsesServerKeysAndValues() throws {
    let body = try Self.object(
      NewInterviewDTO(
        NewInterview(
          companyName: "A", industry: "IT", jobTitle: "SE", interviewType: .job,
          hiringType: .midCareer, questionCount: 5, faceTracking: true)))
    #expect(body["interviewType"] as? String == "job")
    #expect(body["hiringType"] as? String == "mid_career")
    #expect(body["questionCount"] as? Int == 5)
    #expect(body["faceTracking"] as? Bool == true)
    #expect(
      Set(body.keys) == [
        "companyName", "industry", "jobTitle", "interviewType", "hiringType", "questionCount",
        "faceTracking",
      ])
  }

  @Test func profileLeavesOutEmptyFields() throws {
    let nicknameOnly = try Self.object(
      ProfileDTO(Profile(saved: "太郎", hiringType: nil, industry: nil, jobTitle: nil)))
    #expect(Set(nicknameOnly.keys) == ["nickname"])
    let full = Profile(saved: "花子", hiringType: .newGrad, industry: "商社", jobTitle: "営業")
    #expect(try Self.roundTrip(ProfileDTO(full)).domain == full)
    #expect(try Self.object(ProfileDTO(full))["hiringType"] as? String == "new_grad")
  }

  // 이전 버전이 이 iPhone에 남긴 프로필 사본을 그대로 읽는다
  @Test func profileStoreReadsProfileSavedBefore() throws {
    let defaults = try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)"))
    defaults.set(
      Data(#"{"nickname":"太郎","hiringType":"mid_career","industry":"商社"}"#.utf8),
      forKey: "profile")
    let store = ProfileStore(defaults: defaults)
    #expect(
      store.profile == Profile(saved: "太郎", hiringType: .midCareer, industry: "商社", jobTitle: nil))
    let profile = Profile(saved: "花子", hiringType: nil, industry: nil, jobTitle: "営業")
    store.save(profile)
    #expect(store.profile == profile)
  }

  @Test func consentsUseDocumentVersions() throws {
    let body = try Self.object(ConsentsRequestDTO([.terms, .privacy]))
    let consents = try #require(body["consents"] as? [[String: String]])
    #expect(
      consents == [
        ["document": "terms", "version": LegalDocument.terms.version],
        ["document": "privacy", "version": LegalDocument.privacy.version],
      ])
  }

  @Test func appleSignInSendsTokenAndNonce() throws {
    let body = try Self.object(
      AppleSignInRequestDTO(AppleSignInRequest(identityToken: "token", nonce: "nonce")))
    #expect(body as? [String: String] == ["identityToken": "token", "nonce": "nonce"])
  }
}
