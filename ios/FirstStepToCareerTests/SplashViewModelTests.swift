import Foundation
import Testing

@testable import FirstStepToCareer

// StubURLProtocol을 함께 쓰므로 APIClientTests(.serialized) 안에서 돈다
extension APIClientTests {
  // 애니메이션 시간을 줄여 빠르게 확인한다
  @MainActor
  private func splash(
    storedId: String? = nil, hasStarted: Bool = false, animation: Duration = .milliseconds(300),
    limit: Duration = .seconds(2), extraDelay: Duration = .zero,
    routes: @escaping (String, String) -> (Int, String) = { _, _ in (200, #"{"aiEnabled":true}"#) }
  ) throws -> (SplashViewModel, ActiveInterviewStore, Recorder) {
    let store = try activeStore(storedId: storedId)
    let recorder = stubRoutes(routes)
    let model = SplashViewModel(
      api: client, hasStarted: hasStarted, store: store,
      timing: SplashViewModel.Timing(animation: animation, loadingLimit: limit),
      extraDelay: extraDelay)
    return (model, store, recorder)
  }

  @MainActor @Test func splashMovesOnRightAfterAnimationWhenReady() async throws {
    let (model, _, recorder) = try splash()
    await model.run()
    #expect(model.isFinished)
    #expect(!model.showsLoading)
    #expect(recorder.items == ["GET /v1/status"])
  }

  @MainActor @Test func splashShowsLoadingUntilSlowPreparationEnds() async throws {
    let (model, _, _) = try splash(animation: .milliseconds(50), extraDelay: .milliseconds(400))
    let elapsed = await ContinuousClock().measure { await model.run() }
    #expect(model.showsLoading)
    #expect(model.isReady)
    // 넘어가는 동안 마지막 안내 문구를 유지한다
    #expect(model.step == .connecting)
    #expect(elapsed < .seconds(2))
  }

  @MainActor @Test func splashMovesOnAfterLoadingLimit() async throws {
    let (model, _, _) = try splash(
      animation: .milliseconds(50), limit: .milliseconds(200), extraDelay: .seconds(2))
    let elapsed = await ContinuousClock().measure { await model.run() }
    #expect(model.isFinished)
    #expect(model.showsLoading)
    #expect(!model.isReady)
    #expect(elapsed < .seconds(1))
  }

  @MainActor @Test func splashTreatsConnectionFailureAsReady() async throws {
    let (model, _, _) = try splash { _, _ in
      (500, #"{"error":{"code":"INTERNAL","message":"x"}}"#)
    }
    await model.run()
    #expect(model.isFinished)
    #expect(!model.showsLoading)
  }

  @MainActor @Test func splashSkipsInterviewCleanupBeforeStart() async throws {
    let (model, store, recorder) = try splash(storedId: "i1", hasStarted: false)
    await model.run()
    #expect(recorder.items == ["GET /v1/status"])
    #expect(store.interviewId == "i1")
  }

  @MainActor @Test func splashDeletesUnfinishedInterviewAfterStart() async throws {
    let (model, store, recorder) = try splash(storedId: "i1", hasStarted: true) { method, path in
      switch (method, path) {
      case ("GET", "/v1/status"): (200, #"{"aiEnabled":true}"#)
      case ("DELETE", _): (204, "")
      default: (200, Self.detail(status: "in_progress"))
      }
    }
    await model.run()
    #expect(
      recorder.items == [
        "GET /v1/status", "GET /v1/interviews/i1", "DELETE /v1/interviews/i1",
      ])
    #expect(store.interviewId == nil)
    #expect(!model.showsLoading)
  }
}
