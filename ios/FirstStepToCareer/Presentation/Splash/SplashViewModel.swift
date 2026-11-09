import Foundation
import Observation

// 스플래시 동안 앱을 시작할 준비를 하고, 화면을 넘길 때를 정한다 (SITE_MAP S-13)
@MainActor
@Observable
final class SplashViewModel {
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

  private let checkServiceStatus: CheckServiceStatusUseCase
  private let deleteUnfinishedInterview: DeleteUnfinishedInterviewUseCase
  private let hasStarted: Bool
  private let timing: Timing
  // 준비가 늦은 상황을 확인하려고 일부러 늦춘다. 평소에는 0
  private let extraDelay: Duration

  init(
    checkServiceStatus: CheckServiceStatusUseCase,
    deleteUnfinishedInterview: DeleteUnfinishedInterviewUseCase, hasStarted: Bool,
    timing: Timing = Timing(), extraDelay: Duration = .zero
  ) {
    self.checkServiceStatus = checkServiceStatus
    self.deleteUnfinishedInterview = deleteUnfinishedInterview
    self.hasStarted = hasStarted
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
    _ = try? await checkServiceStatus.execute()
    if extraDelay > .zero { try? await Task.sleep(for: extraDelay) }
    if hasStarted && deleteUnfinishedInterview.hasUnfinishedInterview {
      step = .checkingInterview
      await deleteUnfinishedInterview.execute()
    }
    // step은 비우지 않는다. 사라지는 동안 안내 문구가 다른 문구로 바뀌어 보이지 않게 한다
    isReady = true
  }
}
