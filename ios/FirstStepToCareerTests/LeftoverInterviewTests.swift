import Foundation
import Testing

@testable import FirstStepToCareer

// 남은 면접 정리 UseCase를 실제 저장소와 가짜 서버로 확인한다.
// StubURLProtocol을 함께 쓰므로 APIClientTests(.serialized) 안에서 돈다
extension APIClientTests {
  private func deleteUnfinished(
    storedId: String?, routes: @escaping (String, String) -> (Int, String)
  ) async throws -> (ActiveInterviewStore, Recorder) {
    let store = try activeStore(storedId: storedId)
    let recorder = stubRoutes(routes)
    await DeleteUnfinishedInterviewUseCase(
      interviews: APIInterviewRepository(api: client), activeInterview: store
    ).execute()
    return (store, recorder)
  }

  private func evaluatePending(routes: @escaping (String, String) -> (Int, String)) async
    -> Recorder
  {
    let recorder = stubRoutes(routes)
    await EvaluatePendingInterviewsUseCase(
      status: APIServiceStatusRepository(api: client),
      interviews: APIInterviewRepository(api: client)
    ).execute()
    return recorder
  }

  @Test func deletesUnfinishedInterviewStartedOnThisDevice() async throws {
    let (store, recorder) = try await deleteUnfinished(storedId: "i1") { method, _ in
      method == "DELETE" ? (204, "") : (200, Self.detail(status: "in_progress"))
    }
    #expect(recorder.items == ["GET /v1/interviews/i1", "DELETE /v1/interviews/i1"])
    #expect(store.interviewId == nil)
  }

  @Test func keepsAwaitingInterviewInsteadOfDeleting() async throws {
    let (store, recorder) = try await deleteUnfinished(storedId: "i1") { _, _ in
      (200, Self.detail(status: "awaiting_evaluation"))
    }
    #expect(recorder.items == ["GET /v1/interviews/i1"])
    #expect(store.interviewId == nil)
  }

  @Test func forgetsInterviewThatNoLongerExists() async throws {
    let (store, _) = try await deleteUnfinished(storedId: "i1") { _, _ in
      (404, #"{"error":{"code":"NOT_FOUND","message":"none"}}"#)
    }
    #expect(store.interviewId == nil)
  }

  @Test func keepsInterviewIdWhenDeleteFails() async throws {
    let (store, _) = try await deleteUnfinished(storedId: "i1") { method, _ in
      method == "DELETE"
        ? (500, #"{"error":{"code":"INTERNAL","message":"x"}}"#)
        : (200, Self.detail(status: "in_progress"))
    }
    #expect(store.interviewId == "i1")
  }

  @Test func doesNothingWithoutStoredInterview() async throws {
    let (_, recorder) = try await deleteUnfinished(storedId: nil) { _, _ in (500, "") }
    #expect(recorder.items.isEmpty)
  }

  @Test func evaluatesOnlyAwaitingInterviewsAcrossPages() async throws {
    let recorder = await evaluatePending { method, path in
      switch (method, path) {
      case ("GET", "/v1/status"): return (200, #"{"aiEnabled":true}"#)
      case ("GET", "/v1/interviews"):
        return (
          200,
          #"{"items":["# + Self.summary(id: "a", status: "awaiting_evaluation") + ","
            + Self.summary(id: "b", status: "completed") + #"],"nextCursor":"c1"}"#
        )
      case ("GET", "/v1/interviews?cursor=c1"):
        return (
          200,
          #"{"items":["# + Self.summary(id: "c", status: "awaiting_evaluation") + ","
            + Self.summary(id: "d", status: "in_progress") + #"],"nextCursor":null}"#
        )
      default: return (200, Self.detail(status: "completed"))
      }
    }
    #expect(
      recorder.items.filter { $0.hasPrefix("POST") } == [
        "POST /v1/interviews/a/evaluation", "POST /v1/interviews/c/evaluation",
      ])
  }

  @Test func skipsEvaluationWhenAIIsOff() async throws {
    let recorder = await evaluatePending { _, _ in (200, #"{"aiEnabled":false}"#) }
    #expect(recorder.items == ["GET /v1/status"])
  }
}
