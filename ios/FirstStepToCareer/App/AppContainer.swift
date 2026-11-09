import Foundation

// 앱이 쓰는 실제 부품을 만들어 화면에 넘길 UseCase 모음으로 묶는다
enum AppContainer {
  static func makeUseCases(api: APIClient = .fromBundle()) -> UseCases {
    UseCases(
      interviews: APIInterviewRepository(api: api), accounts: APIAccountRepository(api: api),
      profiles: APIProfileRepository(api: api), status: APIServiceStatusRepository(api: api),
      settings: LocalAppSettingsRepository(), profileCache: ProfileStore(),
      activeInterview: ActiveInterviewStore(), nonces: SystemSignInNonce())
  }
}
