import SwiftUI

// 화면이 쓰는 UseCase 모음. Domain의 약속만 받아 만들고, 실제 저장소는 App이 넣는다
struct UseCases: Sendable {
  // 앱 시작과 온보딩
  let getLaunchState: GetLaunchStateUseCase
  let acceptTerms: AcceptTermsUseCase
  let chooseStart: ChooseStartUseCase
  let completeOnboarding: CompleteOnboardingUseCase
  let resetLocalData: ResetLocalDataUseCase
  let checkServiceStatus: CheckServiceStatusUseCase
  let deleteUnfinishedInterview: DeleteUnfinishedInterviewUseCase
  let evaluatePendingInterviews: EvaluatePendingInterviewsUseCase
  // 계정
  let makeSignInChallenge: MakeSignInChallengeUseCase
  let signInWithApple: SignInWithAppleUseCase
  let getAccountType: GetAccountTypeUseCase
  let signOut: SignOutUseCase
  let deleteAllData: DeleteAllDataUseCase
  // 프로필
  let loadProfile: LoadProfileUseCase
  let saveProfile: SaveProfileUseCase
  let recordConsents: RecordConsentsUseCase
  let getCachedProfile: GetCachedProfileUseCase
  // 모의면접과 기록
  let getQuestionCount: GetQuestionCountUseCase
  let saveQuestionCount: SaveQuestionCountUseCase
  let calibrateFace: CalibrateFaceUseCase
  let startInterview: StartInterviewUseCase
  let submitAnswer: SubmitAnswerUseCase
  let quitInterview: QuitInterviewUseCase
  let loadInterview: LoadInterviewUseCase
  let evaluateInterview: EvaluateInterviewUseCase
  let deleteInterview: DeleteInterviewUseCase
  let loadCompletedInterviews: LoadCompletedInterviewsUseCase

  init(
    interviews: any InterviewRepository, accounts: any AccountRepository,
    profiles: any ProfileRepository, status: any ServiceStatusRepository,
    settings: any AppSettingsRepository, profileCache: any ProfileCacheRepository,
    activeInterview: any ActiveInterviewRepository, nonces: any SignInNonceGenerating
  ) {
    getLaunchState = GetLaunchStateUseCase(settings: settings, profileCache: profileCache)
    acceptTerms = AcceptTermsUseCase(settings: settings)
    chooseStart = ChooseStartUseCase(settings: settings)
    completeOnboarding = CompleteOnboardingUseCase(settings: settings)
    resetLocalData = ResetLocalDataUseCase(
      settings: settings, profileCache: profileCache, activeInterview: activeInterview)
    checkServiceStatus = CheckServiceStatusUseCase(status: status)
    deleteUnfinishedInterview = DeleteUnfinishedInterviewUseCase(
      interviews: interviews, activeInterview: activeInterview)
    evaluatePendingInterviews = EvaluatePendingInterviewsUseCase(
      status: status, interviews: interviews)
    makeSignInChallenge = MakeSignInChallengeUseCase(nonces: nonces)
    signInWithApple = SignInWithAppleUseCase(accounts: accounts)
    getAccountType = GetAccountTypeUseCase(accounts: accounts)
    signOut = SignOutUseCase(accounts: accounts)
    deleteAllData = DeleteAllDataUseCase(accounts: accounts)
    loadProfile = LoadProfileUseCase(profiles: profiles, profileCache: profileCache)
    saveProfile = SaveProfileUseCase(profiles: profiles, profileCache: profileCache)
    recordConsents = RecordConsentsUseCase(profiles: profiles)
    getCachedProfile = GetCachedProfileUseCase(profileCache: profileCache)
    getQuestionCount = GetQuestionCountUseCase(settings: settings)
    saveQuestionCount = SaveQuestionCountUseCase(settings: settings)
    calibrateFace = CalibrateFaceUseCase()
    startInterview = StartInterviewUseCase(interviews: interviews, activeInterview: activeInterview)
    submitAnswer = SubmitAnswerUseCase(interviews: interviews, activeInterview: activeInterview)
    quitInterview = QuitInterviewUseCase(interviews: interviews, activeInterview: activeInterview)
    loadInterview = LoadInterviewUseCase(interviews: interviews)
    evaluateInterview = EvaluateInterviewUseCase(interviews: interviews)
    deleteInterview = DeleteInterviewUseCase(interviews: interviews)
    loadCompletedInterviews = LoadCompletedInterviewsUseCase(interviews: interviews)
  }
}

extension EnvironmentValues {
  // 빠지면 화면이 조용히 아무것도 하지 않게 되므로 바로 멈춘다
  var useCases: UseCases {
    guard let providedUseCases else { preconditionFailure("App이 useCases(_:)로 넣지 않았다") }
    return providedUseCases
  }

  // SwiftUI는 값을 넣기 전에 지금 값을 한 번 읽으므로, 넣는 쪽은 비어 있어도 되는 값으로 둔다
  @Entry fileprivate var providedUseCases: UseCases?
  @Entry var appInfo = AppInfo(version: "-", appleSignInEnabled: false)
}

extension View {
  // App이 앱을 시작할 때 넣는다
  func useCases(_ useCases: UseCases) -> some View {
    environment(\.providedUseCases, useCases)
  }
}
