import Foundation
import Observation

// 면접 탭의 첫 화면 상태. AI 상태와 응모처·면접 조건 입력 (SITE_MAP S-01)
@MainActor
@Observable
final class InterviewHomeViewModel {
  enum Availability: Equatable {
    case loading
    case available
    case aiDisabled
    case failed
  }

  private(set) var availability = Availability.loading
  var form: InterviewForm

  @ObservationIgnored private let checkServiceStatus: CheckServiceStatusUseCase
  @ObservationIgnored private let getCachedProfile: GetCachedProfileUseCase
  @ObservationIgnored private let saveQuestionCountUseCase: SaveQuestionCountUseCase

  // 프로필의 희망 조건과 마지막으로 고른 질문 수로 미리 채운다
  init(
    checkServiceStatus: CheckServiceStatusUseCase, getCachedProfile: GetCachedProfileUseCase,
    getQuestionCount: GetQuestionCountUseCase, saveQuestionCount: SaveQuestionCountUseCase
  ) {
    self.checkServiceStatus = checkServiceStatus
    self.getCachedProfile = getCachedProfile
    saveQuestionCountUseCase = saveQuestionCount
    form = InterviewForm(
      profile: getCachedProfile.execute(), questionCount: getQuestionCount.execute())
  }

  // 탭을 오갈 때마다 다시 확인한다. 확인하는 동안에는 이전 상태를 그대로 보여 준다
  func refresh() async {
    do {
      availability = try await checkServiceStatus.execute() ? .available : .aiDisabled
    } catch {
      // 탭을 옮겨 확인이 취소된 것은 연결 실패가 아니다
      if Task.isCancelled { return }
      availability = .failed
    }
  }

  func retry() {
    availability = .loading
    Task { await refresh() }
  }

  // 메뉴에서 프로필을 바꾸고 돌아왔을 때 반영한다
  func syncProfile() {
    form.sync(profile: getCachedProfile.execute())
  }

  // 마지막으로 고른 질문 수로 다음에도 시작한다
  func saveQuestionCount(_ count: Int) {
    saveQuestionCountUseCase.execute(count)
  }
}

extension InterviewHomeViewModel {
  convenience init(_ useCases: UseCases) {
    self.init(
      checkServiceStatus: useCases.checkServiceStatus, getCachedProfile: useCases.getCachedProfile,
      getQuestionCount: useCases.getQuestionCount, saveQuestionCount: useCases.saveQuestionCount)
  }
}
