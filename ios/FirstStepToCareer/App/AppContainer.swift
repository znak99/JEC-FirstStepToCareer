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

#if DEBUG
  extension UseCases {
    // Xcode 미리보기용. 아무것도 받지 않는 주소(localhost:9)를 불러 실제 서버에 닿지 않는다
    static let preview = AppContainer.makeUseCases(
      api: APIClient(baseURL: URL(string: "http://localhost:9")!))
  }
#endif
