import Foundation

// 앱 시작과 온보딩 진행 상태 (ARCHITECTURE.md 6.3, SITE_MAP 2절)

struct GetLaunchStateUseCase: Sendable {
  let settings: any AppSettingsRepository
  let profileCache: any ProfileCacheRepository

  func execute() -> LaunchState {
    LaunchState(
      hasAgreed: settings.hasAgreed, hasStarted: settings.hasStarted,
      hasChosenStart: settings.hasChosenStart, hasProfile: profileCache.profile != nil,
      hasOutdatedAgreement: settings.hasOutdatedAgreement)
  }
}

// 지금 버전의 약관에 동의했다고 이 iPhone에 남긴다
struct AcceptTermsUseCase: Sendable {
  let settings: any AppSettingsRepository

  func execute() { settings.saveAgreement() }
}

// 온보딩에서 시작(로그인 방식)을 골랐다고 남긴다. 정보 입력 도중 앱이 꺼지면 다음에 정보 입력부터 이어 한다
struct ChooseStartUseCase: Sendable {
  let settings: any AppSettingsRepository

  func execute() { settings.setHasChosenStart(true) }
}

struct CompleteOnboardingUseCase: Sendable {
  let settings: any AppSettingsRepository

  func execute() { settings.setHasStarted(true) }
}

// 로그아웃·데이터 삭제 뒤 온보딩부터 다시 하도록 이 iPhone의 값을 지운다.
// 이전 계정의 면접이므로 남은 면접 ID도 지운다
struct ResetLocalDataUseCase: Sendable {
  let settings: any AppSettingsRepository
  let profileCache: any ProfileCacheRepository
  let activeInterview: any ActiveInterviewRepository

  func execute() {
    activeInterview.clear()
    profileCache.clear()
    settings.clearAgreement()
    settings.setHasChosenStart(false)
    settings.setHasStarted(false)
  }
}

// AI 스위치가 켜져 있는지. 연결하지 못하면 오류를 던진다
struct CheckServiceStatusUseCase: Sendable {
  let status: any ServiceStatusRepository

  func execute() async throws -> Bool {
    try await status.isAIEnabled()
  }
}

// 도중에 앱이 꺼진 이 iPhone의 면접을 지운다. 실패해도 알리지 않고 다음 실행 때 다시 시도한다
struct DeleteUnfinishedInterviewUseCase: Sendable {
  let interviews: any InterviewRepository
  let activeInterview: any ActiveInterviewRepository

  var hasUnfinishedInterview: Bool { activeInterview.interviewId != nil }

  func execute() async {
    guard let id = activeInterview.interviewId else { return }
    do {
      // 마지막 답변 직후에 꺼졌다면 평가 대기일 수 있으므로 진행 중일 때만 지운다
      if try await interviews.detail(id: id).status == .inProgress {
        try await interviews.delete(id: id)
      }
      activeInterview.clear()
    } catch let error as any RepositoryError where error.isRejected {
      // 이미 없거나 다른 계정의 면접이면 더 할 일이 없다
      activeInterview.clear()
    } catch {
      // 통신 실패 등은 다음 실행 때 다시 시도한다
    }
  }
}

// 점수를 받지 못한 면접을 평가한다. AI가 꺼져 있으면 비용이 들지 않게 목록도 받지 않는다
struct EvaluatePendingInterviewsUseCase: Sendable {
  let status: any ServiceStatusRepository
  let interviews: any InterviewRepository

  func execute() async {
    do {
      guard try await status.isAIEnabled() else { return }
      let pending = try await interviews.all()
        .filter { $0.status == .awaitingEvaluation }.map(\.id)
      for id in pending {
        _ = try? await interviews.evaluate(id: id)
      }
    } catch {
      // 다음 실행 때 다시 시도한다
    }
  }
}
