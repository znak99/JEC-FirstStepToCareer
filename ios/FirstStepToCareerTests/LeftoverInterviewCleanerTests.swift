import Foundation
import Testing

@testable import FirstStepToCareer

// 남은 면접 정리 UseCase를 실제 저장소와 가짜 서버로 확인한다
private struct Cleaner {
  let unfinished: DeleteUnfinishedInterviewUseCase
  let pending: EvaluatePendingInterviewsUseCase

  func deleteUnfinished() async { await unfinished.execute() }
  func evaluatePending() async { await pending.execute() }
}

// StubURLProtocol을 함께 쓰므로 APIClientTests(.serialized) 안에서 돈다
extension APIClientTests {
  private func cleaner(
    storedId: String?, routes: @escaping (String, String) -> (Int, String)
  ) throws -> (Cleaner, ActiveInterviewStore, Recorder) {
    let store = try activeStore(storedId: storedId)
    let recorder = stubRoutes(routes)
    let interviews = APIInterviewRepository(api: client)
    let cleaner = Cleaner(
      unfinished: DeleteUnfinishedInterviewUseCase(interviews: interviews, activeInterview: store),
      pending: EvaluatePendingInterviewsUseCase(
        status: APIServiceStatusRepository(api: client), interviews: interviews))
    return (cleaner, store, recorder)
  }

  @Test func deletesUnfinishedInterviewStartedOnThisDevice() async throws {
    let (cleaner, store, recorder) = try cleaner(storedId: "i1") { method, _ in
      method == "DELETE" ? (204, "") : (200, Self.detail(status: "in_progress"))
    }
    await cleaner.deleteUnfinished()
    #expect(recorder.items == ["GET /v1/interviews/i1", "DELETE /v1/interviews/i1"])
    #expect(store.interviewId == nil)
  }

  @Test func keepsAwaitingInterviewInsteadOfDeleting() async throws {
    let (cleaner, store, recorder) = try cleaner(storedId: "i1") { _, _ in
      (200, Self.detail(status: "awaiting_evaluation"))
    }
    await cleaner.deleteUnfinished()
    #expect(recorder.items == ["GET /v1/interviews/i1"])
    #expect(store.interviewId == nil)
  }

  @Test func forgetsInterviewThatNoLongerExists() async throws {
    let (cleaner, store, _) = try cleaner(storedId: "i1") { _, _ in
      (404, #"{"error":{"code":"NOT_FOUND","message":"none"}}"#)
    }
    await cleaner.deleteUnfinished()
    #expect(store.interviewId == nil)
  }

  @Test func keepsInterviewIdWhenDeleteFails() async throws {
    let (cleaner, store, _) = try cleaner(storedId: "i1") { method, _ in
      method == "DELETE"
        ? (500, #"{"error":{"code":"INTERNAL","message":"x"}}"#)
        : (200, Self.detail(status: "in_progress"))
    }
    await cleaner.deleteUnfinished()
    #expect(store.interviewId == "i1")
  }

  @Test func doesNothingWithoutStoredInterview() async throws {
    let (cleaner, _, recorder) = try cleaner(storedId: nil) { _, _ in (500, "") }
    await cleaner.deleteUnfinished()
    #expect(recorder.items.isEmpty)
  }

  @Test func evaluatesOnlyAwaitingInterviewsAcrossPages() async throws {
    let (cleaner, _, recorder) = try cleaner(storedId: nil) { method, path in
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
    await cleaner.evaluatePending()
    #expect(
      recorder.items.filter { $0.hasPrefix("POST") } == [
        "POST /v1/interviews/a/evaluation", "POST /v1/interviews/c/evaluation",
      ])
  }

  @Test func skipsEvaluationWhenAIIsOff() async throws {
    let (cleaner, _, recorder) = try cleaner(storedId: nil) { _, _ in
      (200, #"{"aiEnabled":false}"#)
    }
    await cleaner.evaluatePending()
    #expect(recorder.items == ["GET /v1/status"])
  }
}
