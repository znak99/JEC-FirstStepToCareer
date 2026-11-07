import Foundation
import Observation

// 스플래시 동안 앱을 시작할 준비를 하고, 화면을 넘길 때를 정한다 (SITE_MAP S-13)
@MainActor
@Observable
final class SplashModel {
  enum Step: Equatable {
    case connecting
    case checkingInterview
  }

  struct Timing {
    // 애니메이션이 끝나고 완성된 로고를 잠깐 보여 준 시점
    var animation: Duration = .seconds(SplashTimeline.decision)
    // 로딩 표시를 띄운 뒤 더 기다리는 최대 시간
    var loadingLimit: Duration = .seconds(3)
  }

  private(set) var step: Step?
  private(set) var isReady = false
  private(set) var showsLoading = false
  private(set) var isFinished = false

  private let api: APIClient
  private let hasStarted: Bool
  private let store: ActiveInterviewStore
  private let timing: Timing
  // 준비가 늦은 상황을 확인하려고 일부러 늦춘다. 평소에는 0
  private let extraDelay: Duration

  init(
    api: APIClient, hasStarted: Bool, store: ActiveInterviewStore = ActiveInterviewStore(),
    timing: Timing = Timing(), extraDelay: Duration = .zero
  ) {
    self.api = api
    self.hasStarted = hasStarted
    self.store = store
    self.timing = timing
    self.extraDelay = extraDelay
  }

  func run() async {
    // 화면을 먼저 넘겨도 준비는 끝까지 진행한다
    Task { await prepare() }
    try? await Task.sleep(for: timing.animation)
    if !isReady {
      showsLoading = true
      let deadline = ContinuousClock.now + timing.loadingLimit
      while !isReady && ContinuousClock.now < deadline && !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(50))
      }
    }
    isFinished = true
  }

  // 실패해도 준비가 끝난 것으로 본다. 연결 문제는 다음 화면이 안내한다
  private func prepare() async {
    step = .connecting
    _ = try? await api.status()
    if extraDelay > .zero { try? await Task.sleep(for: extraDelay) }
    if hasStarted && store.interviewId != nil {
      step = .checkingInterview
      await LeftoverInterviewCleaner(api: api, store: store).deleteUnfinished()
    }
    // step은 비우지 않는다. 사라지는 동안 안내 문구가 다른 문구로 바뀌어 보이지 않게 한다
    isReady = true
  }
}
