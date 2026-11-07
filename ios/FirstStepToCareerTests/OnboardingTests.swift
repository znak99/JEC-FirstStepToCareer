import Foundation
import Testing

@testable import FirstStepToCareer

struct ProfileTests {
  private func make(
    _ nickname: String, hiringType: HiringType? = nil, industry: String = "", jobTitle: String = ""
  ) -> Profile? {
    Profile(nickname: nickname, hiringType: hiringType, industry: industry, jobTitle: jobTitle)
  }

  @Test(arguments: ["", "   ", "\n\t", "　"])
  func rejectsBlankNickname(_ nickname: String) {
    #expect(make(nickname) == nil)
  }

  @Test func trimsNicknameAndKeepsOptionalsEmpty() throws {
    let profile = try #require(make("  たろう \n"))
    #expect(profile.nickname == "たろう")
    #expect(profile.hiringType == nil)
    #expect(profile.industry == nil)
    #expect(profile.jobTitle == nil)
  }

  @Test func acceptsNicknameUpToLimit() {
    #expect(make("あ")?.nickname == "あ")
    #expect(make(String(repeating: "あ", count: 20)) != nil)
    #expect(make(String(repeating: "あ", count: 21)) == nil)
    // 공백은 지운 뒤에 센다
    #expect(make(" " + String(repeating: "a", count: 20) + " ") != nil)
  }

  @Test func countsEmojiAndSymbolsAsCharacters() {
    #expect(make("👨‍👩‍👧")?.nickname == "👨‍👩‍👧")
    #expect(make(String(repeating: "👍🏽", count: 20)) != nil)
    #expect(make("<script>'\"&;")?.nickname == "<script>'\"&;")
  }

  @Test func keepsOptionalChoices() throws {
    let profile = try #require(
      make("たろう", hiringType: .midCareer, industry: " IT ", jobTitle: "営業"))
    #expect(profile.hiringType == .midCareer)
    #expect(profile.industry == "IT")
    #expect(profile.jobTitle == "営業")
  }

  @Test func treatsBlankChoicesAsUnset() throws {
    let profile = try #require(make("たろう", industry: "  ", jobTitle: "\n"))
    #expect(profile.industry == nil)
    #expect(profile.jobTitle == nil)
  }

  @Test func rejectsChoicesOverLimit() {
    #expect(make("たろう", industry: String(repeating: "業", count: 50)) != nil)
    #expect(make("たろう", industry: String(repeating: "業", count: 51)) == nil)
    #expect(make("たろう", jobTitle: String(repeating: "職", count: 51)) == nil)
  }
}

struct OnboardingStorageTests {
  private func defaults() throws -> UserDefaults {
    try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)"))
  }

  @Test func agreementCoversCurrentVersionsAndCanBeCleared() throws {
    let defaults = try defaults()
    #expect(AppSettings.hasAgreed(in: defaults) == false)
    AppSettings.saveAgreement(in: defaults)
    #expect(AppSettings.hasAgreed(in: defaults))
    AppSettings.clearAgreement(in: defaults)
    #expect(AppSettings.hasAgreed(in: defaults) == false)
  }

  @Test func agreementToOldVersionDoesNotCount() throws {
    let defaults = try defaults()
    defaults.set(
      ["terms": "2000-01-01", "privacy": "2000-01-01"], forKey: "agreedDocumentVersions")
    #expect(AppSettings.hasAgreed(in: defaults) == false)
  }

  @Test func profileStoreSavesLoadsAndClears() throws {
    let store = ProfileStore(defaults: try defaults())
    #expect(store.profile == nil)
    let profile = try #require(
      Profile(nickname: "たろう", hiringType: .newGrad, industry: "IT", jobTitle: ""))
    store.save(profile)
    #expect(store.profile == profile)
    store.clear()
    #expect(store.profile == nil)
  }
}

struct ProfileDraftTests {
  @Test func catalogValuesAreChosenAndOthersGoToOtherInput() throws {
    let profile = try #require(
      Profile(nickname: "たろう", hiringType: .midCareer, industry: "銀行・信用金庫", jobTitle: "宇宙飛行士"))
    let draft = ProfileDraft(profile)
    #expect(draft.nickname == "たろう")
    #expect(draft.hiringType == .midCareer)
    #expect(draft.industryChoice == "銀行・信用金庫")
    #expect(draft.otherIndustry == "")
    #expect(draft.jobChoice == ProfileDraft.other)
    #expect(draft.otherJob == "宇宙飛行士")
    #expect(draft.profile == profile)
  }

  @Test func emptyValuesStayUnselected() throws {
    let draft = ProfileDraft(
      try #require(Profile(nickname: "a", hiringType: nil, industry: "", jobTitle: "")))
    #expect(draft.industryChoice == "")
    #expect(draft.jobChoice == "")
    #expect(ProfileDraft.split(nil, in: ChoiceCatalog.industries) == ("", ""))
  }

  @Test func oldListValuesBecomeOtherInput() {
    // 예전 목록의 값(「IT」 등)은 새 목록에 없으므로 직접 입력한 값으로 보여 준다
    #expect(ProfileDraft.split("IT", in: ChoiceCatalog.industries) == (ProfileDraft.other, "IT"))
  }

  @Test func blankDraftHasNoProfile() {
    #expect(ProfileDraft().profile == nil)
  }
}

struct AppStageTests {
  @Test func newUserGoesConsentStartProfileTabs() {
    #expect(
      AppStage.of(hasAgreed: false, hasStarted: false, choseStart: false, hasProfile: false)
        == .consent)
    #expect(
      AppStage.of(hasAgreed: true, hasStarted: false, choseStart: false, hasProfile: false)
        == .start)
    #expect(
      AppStage.of(hasAgreed: true, hasStarted: false, choseStart: true, hasProfile: false)
        == .profile)
    #expect(
      AppStage.of(hasAgreed: true, hasStarted: true, choseStart: true, hasProfile: true) == .tabs)
  }

  @Test func quittingAfterChoosingStartResumesAtProfile() {
    // 정보 입력 도중 앱이 꺼져도 시작 화면으로 돌아가지 않는다. 이 iPhone에 남은 프로필이 있어도 같다
    #expect(
      AppStage.of(hasAgreed: true, hasStarted: false, choseStart: true, hasProfile: true)
        == .profile)
  }

  @Test func existingUserWithoutOnboardingAgreesAndEntersProfileOnce() {
    #expect(
      AppStage.of(hasAgreed: false, hasStarted: true, choseStart: false, hasProfile: false)
        == .consent)
    #expect(
      AppStage.of(hasAgreed: true, hasStarted: true, choseStart: false, hasProfile: false)
        == .profile)
  }

  @Test func changedTermsAskAgreementInModalOverTabs() {
    // 약관 버전만 바뀐 사용자는 탭 화면을 그대로 보여 주고 그 위에서 동의를 받는다
    #expect(
      AppStage.of(hasAgreed: false, hasStarted: true, choseStart: true, hasProfile: true) == .tabs)
    #expect(AppStage.asksAgreementOverTabs(hasAgreed: false, hasStarted: true, hasProfile: true))
    #expect(
      AppStage.asksAgreementOverTabs(hasAgreed: true, hasStarted: true, hasProfile: true) == false)
    // 온보딩 중이거나 프로필이 없으면 모달이 아니라 동의 화면으로 받는다
    #expect(
      AppStage.asksAgreementOverTabs(hasAgreed: false, hasStarted: false, hasProfile: true)
        == false)
    #expect(
      AppStage.asksAgreementOverTabs(hasAgreed: false, hasStarted: true, hasProfile: false)
        == false)
  }
}

struct OnboardingResumeSettingsTests {
  private func defaults() throws -> UserDefaults {
    try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)"))
  }

  @Test func outdatedAgreementIsOnlyForPreviousVersions() throws {
    let defaults = try defaults()
    // 동의한 적이 없으면 예전 버전 동의도 아니다
    #expect(AppSettings.hasOutdatedAgreement(in: defaults) == false)
    defaults.set(
      ["terms": "2000-01-01", "privacy": "2000-01-01"], forKey: "agreedDocumentVersions")
    #expect(AppSettings.hasOutdatedAgreement(in: defaults))
    AppSettings.saveAgreement(in: defaults)
    #expect(AppSettings.hasOutdatedAgreement(in: defaults) == false)
  }

  @Test func chosenStartIsRememberedAndCleared() throws {
    let defaults = try defaults()
    #expect(AppSettings.hasChosenStart(in: defaults) == false)
    AppSettings.setHasChosenStart(true, in: defaults)
    #expect(AppSettings.hasChosenStart(in: defaults))
    AppSettings.setHasChosenStart(false, in: defaults)
    #expect(AppSettings.hasChosenStart(in: defaults) == false)
  }
}
