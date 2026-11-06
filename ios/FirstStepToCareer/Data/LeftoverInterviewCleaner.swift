import Foundation

// 앱을 처음 켤 때 한 번 실행한다. 실패해도 알리지 않고 다음 실행 때 다시 시도한다
struct LeftoverInterviewCleaner: Sendable {
  let api: APIClient
  var store = ActiveInterviewStore()

  func run() async {
    await deleteUnfinished()
    await evaluatePending()
  }

  // 도중에 앱이 꺼진 이 iPhone의 면접을 지운다
  func deleteUnfinished() async {
    guard let id = store.interviewId else { return }
    do {
      // 마지막 답변 직후에 꺼졌다면 평가 대기일 수 있으므로 진행 중일 때만 지운다
      if try await api.interview(id: id).status == .inProgress {
        try await api.deleteInterview(id: id)
      }
      store.clear()
    } catch APIError.server(let status, _) where (400..<500).contains(status) {
      // 이미 없거나 다른 계정의 면접이면 더 할 일이 없다
      store.clear()
    } catch {
      // 통신 실패 등은 다음 실행 때 다시 시도한다
    }
  }

  // 점수를 받지 못한 면접을 평가한다. AI가 꺼져 있으면 비용이 들지 않게 건너뛴다
  func evaluatePending() async {
    do {
      guard try await api.status().aiEnabled else { return }
      var pending: [String] = []
      var cursor: String?
      repeat {
        let page = try await api.interviews(cursor: cursor)
        pending += page.items.filter { $0.status == .awaitingEvaluation }.map(\.id)
        cursor = page.nextCursor
      } while cursor != nil
      for id in pending {
        _ = try? await api.evaluate(interviewId: id)
      }
    } catch {
      // 다음 실행 때 다시 시도한다
    }
  }
}
