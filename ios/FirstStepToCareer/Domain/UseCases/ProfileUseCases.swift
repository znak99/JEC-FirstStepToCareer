import Foundation

// 프로필과 약관 동의 기록 (SITE_MAP S-15, S-17)

// 서버에 저장된 프로필. 서버에 없거나 받지 못하면 이 iPhone에 남은 사본을 쓴다
struct LoadProfileUseCase: Sendable {
  let profiles: any ProfileRepository
  let profileCache: any ProfileCacheRepository

  func execute() async -> Profile? {
    guard let profile = try? await profiles.fetch() else { return profileCache.profile }
    profileCache.save(profile)
    return profile
  }
}

// 온보딩에서는 동의 기록을 먼저 남긴 뒤 프로필을 저장한다. 저장한 값을 이 iPhone에도 남긴다
struct SaveProfileUseCase: Sendable {
  let profiles: any ProfileRepository
  let profileCache: any ProfileCacheRepository

  func execute(_ profile: Profile, agreeingTo documents: [LegalDocument] = []) async throws {
    if !documents.isEmpty { try await profiles.recordConsents(to: documents) }
    profileCache.save(try await profiles.save(profile) ?? profile)
  }
}

// 약관 버전이 바뀌어 동의만 다시 받을 때 서버에 남긴다
struct RecordConsentsUseCase: Sendable {
  let profiles: any ProfileRepository

  func execute(_ documents: [LegalDocument]) async throws {
    try await profiles.recordConsents(to: documents)
  }
}

// 이 iPhone에 남은 프로필 사본. 서버를 기다리지 않고 화면을 바로 채울 때 쓴다
struct GetCachedProfileUseCase: Sendable {
  let profileCache: any ProfileCacheRepository

  func execute() -> Profile? { profileCache.profile }
}
