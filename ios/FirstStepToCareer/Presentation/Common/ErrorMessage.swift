import Foundation

// 서버 요청이 실패했을 때 화면에 보여 줄 문구. 면접 준비·진행·결과 화면이 함께 쓴다
enum ErrorMessage {
  static var aiDisabled: String { String(localized: "現在、AI機能は停止中です。") }

  static func text(for error: Error) -> String {
    switch error as? APIError {
    case let error? where error.isAIDisabled: aiDisabled
    case .network?:
      String(localized: "サーバーに接続できませんでした。通信環境を確認してください。")
    default: String(localized: "応答を取得できませんでした。もう一度お試しください。")
    }
  }
}
