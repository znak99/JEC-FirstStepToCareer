import Foundation
import Testing

@testable import FirstStepToCareer

// 앱 시작 흐름(AppRootViewModel)과 메뉴의 이름 표시
@MainActor
struct RootViewModelTests {
  let settings = MemoryAppSettings()
  let cache = MemoryProfileCache()
  let active = MemoryActiveInterview()
  let accounts = FakeAccountRepository()
  let taro = Profile(saved: "太郎", hiringType: nil, industry: nil, jobTitle: nil)

  private func useCases() -> UseCases {
    UseCases(
      interviews: FakeInterviewRepository(), accounts: accounts, profiles: FakeProfileRepository(),
      status: FakeServiceStatusRepository(), settings: settings, profileCache: cache,
      activeInterview: active, nonces: FakeNonces())
  }

  @Test func onboardingMovesThroughStagesAndKeepsProgress() {
    let model = AppRootViewModel(useCases())
    #expect(model.stage == .consent)
    #expect(!model.isConsentUpdate)
    model.agree()
    #expect(model.stage == .start)
    #expect(settings.hasAgreed)
    model.choseStart()
    #expect(model.stage == .profile)
    #expect(settings.hasChosenStart)
    // 정보 입력 화면이 프로필을 저장한 뒤 부른다
    cache.save(taro)
    model.finishedProfile()
    #expect(model.stage == .tabs)
    #expect(model.hasStarted && settings.hasStarted)
    // 다시 켜면 같은 단계부터 보여 준다
    #expect(AppRootViewModel(useCases()).stage == .tabs)
  }

  @Test func resumesAtProfileWhenAppClosedDuringSetup() {
    settings.saveAgreement()
    settings.setHasChosenStart(true)
    #expect(AppRootViewModel(useCases()).stage == .profile)
  }

  @Test func changedTermsAskAgainOverTabsAfterSplash() {
    settings.hasOutdatedAgreement = true
    settings.setHasStarted(true)
    cache.save(taro)
    let model = AppRootViewModel(useCases())
    #expect(model.stage == .tabs)
    #expect(model.isConsentUpdate)
    #expect(!model.asksAgreement)
    model.showsSplash = false
    #expect(model.asksAgreement)
    model.agree()
    #expect(!model.asksAgreement)
    #expect(settings.hasAgreed)
  }

  @Test func resetStartsOnboardingAgainAndClearsPhone() {
    settings.saveAgreement()
    settings.setHasStarted(true)
    cache.save(taro)
    active.save("i1")
    let model = AppRootViewModel(useCases())
    model.showsSplash = false
    model.reset()
    #expect(model.stage == .consent)
    #expect(!model.hasStarted && !model.isConsentUpdate)
    #expect(!settings.hasAgreed && !settings.hasStarted && !settings.hasChosenStart)
    #expect(cache.profile == nil && active.interviewId == nil)
    // 스플래시를 다시 보여 주지 않는다
    #expect(!model.showsSplash)
  }

  @Test func menuShowsSavedNicknameAndRefreshes() async {
    let model = MenuViewModel(useCases())
    #expect(model.nickname == nil)
    cache.save(taro)
    #expect(model.nickname == nil)
    model.refreshNickname()
    #expect(model.nickname == "太郎")
    await model.loadAccount()
    #expect(model.account == .loaded(.guest))
    #expect(MenuViewModel(useCases()).nickname == "太郎")
  }
}
