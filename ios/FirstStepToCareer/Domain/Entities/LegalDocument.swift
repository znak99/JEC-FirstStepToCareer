import Foundation

// 앱을 쓰기 전에 동의를 받는 문서
enum LegalDocument: String, CaseIterable, Identifiable, Sendable {
  case terms
  case privacy

  var id: Self { self }

  // 본문을 고치면 날짜를 바꾼다. 버전이 바뀌면 다시 동의를 받는다
  var version: String {
    switch self {
    case .terms: "2026-11-07"
    case .privacy: "2026-11-07"
    }
  }
}
