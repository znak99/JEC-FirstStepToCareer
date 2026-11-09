import Testing

@testable import FirstStepToCareer

struct ErrorMessageTests {
  @Test func errorMessages() {
    #expect(
      ErrorMessage.text(for: APIError.server(status: 503, code: "AI_DISABLED"))
        == "現在、AI機能は停止中です。")
    #expect(ErrorMessage.text(for: APIError.network).hasPrefix("サーバーに接続できません"))
    #expect(
      ErrorMessage.text(for: APIError.server(status: 502, code: "AI_FAILED"))
        == "応答を取得できませんでした。もう一度お試しください。")
    #expect(
      ErrorMessage.text(for: APIError.invalidResponse)
        == "応答を取得できませんでした。もう一度お試しください。")
    #expect(
      ErrorMessage.text(for: CancellationError())
        == "応答を取得できませんでした。もう一度お試しください。")
  }

  @Test func recognizesOnlyAIDisabledServerError() {
    #expect(APIError.server(status: 503, code: "AI_DISABLED").isAIDisabled)
    #expect(!APIError.server(status: 502, code: "AI_FAILED").isAIDisabled)
    #expect(!APIError.server(status: 503, code: "ai_disabled").isAIDisabled)
    #expect(!APIError.network.isAIDisabled)
    #expect(!APIError.invalidResponse.isAIDisabled)
  }
}

struct ScoreFormatTests {
  @Test func formatsOneDecimalOrNotEvaluated() {
    #expect(ScoreFormat.text(78.45) == "78.5点" || ScoreFormat.text(78.45) == "78.4点")
    #expect(ScoreFormat.text(100) == "100.0点")
    #expect(ScoreFormat.text(nil) == "評価なし")
  }
}
