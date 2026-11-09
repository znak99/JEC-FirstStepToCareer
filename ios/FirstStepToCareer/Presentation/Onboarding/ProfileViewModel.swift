import Foundation
import Observation

// 프로필을 서버에서 불러오고 저장한다. 온보딩 정보 입력(S-15)과 메뉴의 프로필(S-17)이 함께 쓴다
@MainActor
@Observable
final class ProfileViewModel {
  private(set) var isSaving = false
  var saveFailed = false

  private let loadProfile: LoadProfileUseCase
  private let saveProfile: SaveProfileUseCase
  private let recordConsents: RecordConsentsUseCase

  init(
    loadProfile: LoadProfileUseCase, saveProfile: SaveProfileUseCase,
    recordConsents: RecordConsentsUseCase
  ) {
    self.loadProfile = loadProfile
    self.saveProfile = saveProfile
    self.recordConsents = recordConsents
  }

  // 서버에 저장된 프로필. 서버에 없거나 받지 못하면 이 iPhone에 남은 값을 쓴다
  func load() async -> Profile? {
    await loadProfile.execute()
  }

  // 약관 버전이 바뀌어 동의만 다시 받을 때 쓴다. 성공하면 true
  func agree(to documents: [LegalDocument]) async -> Bool {
    isSaving = true
    defer { isSaving = false }
    do {
      try await recordConsents.execute(documents)
      return true
    } catch {
      saveFailed = true
      return false
    }
  }

  // 온보딩에서는 동의 기록을 먼저 남긴 뒤 프로필을 저장한다. 성공하면 true
  func save(_ profile: Profile, agreeingTo documents: [LegalDocument] = []) async -> Bool {
    isSaving = true
    defer { isSaving = false }
    do {
      try await saveProfile.execute(profile, agreeingTo: documents)
      return true
    } catch {
      saveFailed = true
      return false
    }
  }
}

extension ProfileViewModel {
  convenience init(_ useCases: UseCases) {
    self.init(
      loadProfile: useCases.loadProfile, saveProfile: useCases.saveProfile,
      recordConsents: useCases.recordConsents)
  }
}
