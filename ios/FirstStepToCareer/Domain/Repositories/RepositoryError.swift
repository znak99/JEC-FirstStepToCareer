import Foundation

// 저장소가 던지는 오류 가운데 Domain과 화면이 구분해야 하는 종류
protocol RepositoryError: Error {
  // 없거나 이 계정의 것이 아니어서, 같은 요청을 다시 보내도 소용없는 경우(서버의 4xx)
  var isRejected: Bool { get }
  // AI 스위치가 꺼져 있어 AI를 쓰는 요청이 거절된 경우
  var isAIDisabled: Bool { get }
  // 서버에 닿지 못한 경우
  var isConnectionFailure: Bool { get }
}
