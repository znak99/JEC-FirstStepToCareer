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

  enum Failure: Equatable {
    case signIn
    case signOut
    case delete
  }

  private(set) var account = AccountState.loading
  private(set) var isWorking = false
  var failure: Failure?

  var questionCount: Int {
    didSet { AppSettings.setQuestionCount(questionCount) }
  }

  private let api: APIClient

  init(api: APIClient) {
    self.api = api
    questionCount = AppSettings.questionCount()
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

  // 성공하면 true. 화면은 시작 화면으로 돌아간다
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
  private func run(_ kind: Failure, _ work: () async throws -> Void) async -> Bool {
    guard !isWorking else { return false }
    isWorking = true
    defer { isWorking = false }
    do {
      try await work()
      return true
    } catch {
      failure = kind
      return false
    }
  }
}
