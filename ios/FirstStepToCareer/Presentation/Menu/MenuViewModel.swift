import Foundation
import Observation

@MainActor
@Observable
final class MenuViewModel {
  enum AccountState: Equatable {
    case loading
    case loaded(AccountType)
    case failed
  }

  // 진행 중인 작업과 실패한 작업을 나타낸다
  enum Action: Equatable {
    case signIn
    case signOut
    case delete
  }

  private(set) var account = AccountState.loading
  // 진행 중인 작업. 처리 중 덮개의 문구를 고른다
  private(set) var working: Action?
  var failure: Action?
  // 프로필 줄에 보여 줄 이름. 프로필 화면에서 돌아오면 다시 읽는다
  private(set) var nickname: String?

  var isWorking: Bool { working != nil }

  private let getAccountType: GetAccountTypeUseCase
  private let signInWithApple: SignInWithAppleUseCase
  private let signOutUseCase: SignOutUseCase
  private let deleteAllDataUseCase: DeleteAllDataUseCase
  private let getCachedProfile: GetCachedProfileUseCase

  init(
    getAccountType: GetAccountTypeUseCase, signInWithApple: SignInWithAppleUseCase,
    signOut: SignOutUseCase, deleteAllData: DeleteAllDataUseCase,
    getCachedProfile: GetCachedProfileUseCase
  ) {
    self.getAccountType = getAccountType
    self.signInWithApple = signInWithApple
    signOutUseCase = signOut
    deleteAllDataUseCase = deleteAllData
    self.getCachedProfile = getCachedProfile
    nickname = getCachedProfile.execute()?.nickname
  }

  func refreshNickname() {
    nickname = getCachedProfile.execute()?.nickname
  }

  func loadAccount() async {
    do {
      account = .loaded(try await getAccountType.execute())
    } catch {
      if !Task.isCancelled { account = .failed }
    }
  }

  func signIn(_ request: AppleSignInRequest) async {
    await run(.signIn) { account = .loaded(try await signInWithApple.execute(request)) }
  }

  // 성공하면 true. 화면은 온보딩부터 다시 한다
  func signOut() async -> Bool {
    await run(.signOut) { try await signOutUseCase.execute() }
  }

  func deleteAllData() async -> Bool {
    await run(.delete) { try await deleteAllDataUseCase.execute() }
  }

  func reportSignInFailure() {
    failure = .signIn
  }

  @discardableResult
  private func run(_ kind: Action, _ work: () async throws -> Void) async -> Bool {
    guard !isWorking else { return false }
    working = kind
    defer { working = nil }
    do {
      try await work()
      return true
    } catch {
      failure = kind
      return false
    }
  }
}

extension MenuViewModel {
  convenience init(_ useCases: UseCases) {
    self.init(
      getAccountType: useCases.getAccountType, signInWithApple: useCases.signInWithApple,
      signOut: useCases.signOut, deleteAllData: useCases.deleteAllData,
      getCachedProfile: useCases.getCachedProfile)
  }
}
