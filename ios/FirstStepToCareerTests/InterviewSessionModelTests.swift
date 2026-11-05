import Testing

@testable import FirstStepToCareer

@MainActor
struct InterviewSessionModelTests {
  @Test func errorMessages() {
    #expect(
      InterviewSessionModel.message(for: APIError.server(status: 503, code: "AI_DISABLED"))
        == "現在、AI機能は停止中です。")
    #expect(InterviewSessionModel.message(for: APIError.network).hasPrefix("サーバーに接続できません"))
    #expect(
      InterviewSessionModel.message(for: APIError.server(status: 502, code: "AI_FAILED"))
        == "応答を取得できませんでした。もう一度お試しください。")
  }
}

struct ScoreFormatTests {
  @Test func formatsOneDecimalOrNotEvaluated() {
    #expect(ScoreFormat.text(78.45) == "78.5点" || ScoreFormat.text(78.45) == "78.4点")
    #expect(ScoreFormat.text(100) == "100.0点")
    #expect(ScoreFormat.text(nil) == "評価なし")
  }
}
