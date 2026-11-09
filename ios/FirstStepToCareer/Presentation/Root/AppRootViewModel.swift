import Foundation
import Observation

// 앱을 켜면 스플래시를 먼저 보여 주고, 그 아래에 처음이면 온보딩(동의 → 시작 → 정보 입력)을,
// 그 뒤에는 탭 화면을 둔다. 어느 화면을 보여 줄지는 LaunchState가 정한다 (SITE_MAP 2절)
@MainActor
@Observable
final class AppRootViewModel {
  private(set) var launch: LaunchState
  var showsSplash = true

  @ObservationIgnored private let acceptTerms: AcceptTermsUseCase
  @ObservationIgnored private let chooseStart: ChooseStartUseCase
  @ObservationIgnored private let completeOnboarding: CompleteOnboardingUseCase
  @ObservationIgnored private let resetLocalData: ResetLocalDataUseCase

  init(
    getLaunchState: GetLaunchStateUseCase, acceptTerms: AcceptTermsUseCase,
    chooseStart: ChooseStartUseCase, completeOnboarding: CompleteOnboardingUseCase,
    resetLocalData: ResetLocalDataUseCase
  ) {
    launch = getLaunchState.execute()
    self.acceptTerms = acceptTerms
    self.chooseStart = chooseStart
    self.completeOnboarding = completeOnboarding
    self.resetLocalData = resetLocalData
  }

  var stage: AppStage { launch.stage }
  var hasStarted: Bool { launch.hasStarted }
  // 예전 버전에 동의한 적이 있으면 동의 화면이 약관이 바뀌었다고 안내한다
  var isConsentUpdate: Bool { launch.hasOutdatedAgreement }
  // 약관 버전이 바뀌었으면 스플래시가 끝난 뒤 탭 화면 위에 동의 모달을 띄운다
  var asksAgreement: Bool { !showsSplash && launch.asksAgreementOverTabs }

  func agree() {
    acceptTerms.execute()
    launch.hasAgreed = true
    launch.hasOutdatedAgreement = false
  }

  func choseStart() {
    chooseStart.execute()
    launch.hasChosenStart = true
  }

  // 동의 기록과 프로필은 정보 입력 화면이 서버와 이 iPhone에 저장한다
  func finishedProfile() {
    completeOnboarding.execute()
    launch.hasProfile = true
    launch.hasStarted = true
  }

  // 로그아웃·데이터 삭제 뒤에는 온보딩부터 다시 한다
  func reset() {
    resetLocalData.execute()
    launch = LaunchState(
      hasAgreed: false, hasStarted: false, hasChosenStart: false, hasProfile: false,
      hasOutdatedAgreement: false)
  }
}

extension AppRootViewModel {
  convenience init(_ useCases: UseCases) {
    self.init(
      getLaunchState: useCases.getLaunchState, acceptTerms: useCases.acceptTerms,
      chooseStart: useCases.chooseStart, completeOnboarding: useCases.completeOnboarding,
      resetLocalData: useCases.resetLocalData)
  }
}
