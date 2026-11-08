import Foundation
import Observation

@MainActor
@Observable
final class MenuModel {
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

  var isWorking: Bool { working != nil }

  private let api: APIClient

  init(api: APIClient) {
    self.api = api
  }

  func loadAccount() async {
    do {
      account = .loaded(try await api.me().accountType)
    } catch {
      if !Task.isCancelled { account = .failed }
    }
  }

  func signIn(_ request: AppleSignInRequest) async {
    await run(.signIn) { account = .loaded(try await api.signInWithApple(request).accountType) }
  }

  // 성공하면 true. 화면은 온보딩부터 다시 한다
  func signOut() async -> Bool {
    await run(.signOut) { try await api.signOut() }
  }

  func deleteAllData() async -> Bool {
    await run(.delete) { try await api.deleteAllData() }
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
