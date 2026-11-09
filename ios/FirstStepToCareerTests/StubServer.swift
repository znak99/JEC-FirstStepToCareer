import Foundation
import Testing

@testable import FirstStepToCareer

// 진짜 서버 대신 응답하는 가짜 서버. 응답을 static으로 하나만 두므로,
// 이것을 쓰는 테스트는 모두 APIClientTests(.serialized)의 extension으로 두어 한 번에 하나씩 돌린다
final class StubURLProtocol: URLProtocol {
  nonisolated(unsafe) static var handler: ((URLRequest) -> (Int, Data))?
  nonisolated(unsafe) static var lastRequest: URLRequest?
  nonisolated(unsafe) static var lastBody: Data?

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    Self.lastRequest = request
    Self.lastBody =
      request.httpBody
      ?? request.httpBodyStream.map { stream in
        stream.open()
        defer { stream.close() }
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
          let read = stream.read(buffer, maxLength: 1024)
          if read <= 0 { break }
          data.append(buffer, count: read)
        }
        return data
      }
    let (status, body) = Self.handler?(request) ?? (500, Data())
    let response = HTTPURLResponse(
      url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: body)
    client?.urlProtocolDidFinishLoading(self)
  }
  override func stopLoading() {}
}

// 스텁 서버가 받은 요청을 순서대로 모은다. 요청은 다른 스레드에서 오므로 잠근다
final class Recorder: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [String] = []

  var items: [String] { lock.withLock { storage } }
  func append(_ item: String) { lock.withLock { storage.append(item) } }
}

// 남은 면접 정리·스플래시 테스트가 함께 쓰는 도우미
extension APIClientTests {
  // 진행 중 면접 ID를 테스트마다 새 저장소에 담아 둔다
  func activeStore(storedId: String?) throws -> ActiveInterviewStore {
    let defaults = try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)"))
    let store = ActiveInterviewStore(defaults: defaults)
    if let storedId { store.save(storedId) }
    return store
  }

  // 요청을 "메서드 경로"로 기록하고 경로별로 응답한다
  func stubRoutes(_ routes: @escaping (String, String) -> (Int, String)) -> Recorder {
    let recorder = Recorder()
    StubURLProtocol.handler = { request in
      let method = request.httpMethod ?? ""
      // cursor가 붙은 요청을 구분할 수 있게 쿼리도 포함한다
      let path = (request.url?.path ?? "") + (request.url?.query.map { "?\($0)" } ?? "")
      recorder.append("\(method) \(path)")
      let (status, body) = routes(method, path)
      return (status, Data(body.utf8))
    }
    return recorder
  }

  static func detail(status: String) -> String {
    #"{"id":"i1","companyName":"A","industry":"IT","jobTitle":"SE","interviewType":"hr","hiringType":"new_grad","questionCount":3,"faceTracking":false,"status":""#
      + status
      + #"","startedAt":"2026-11-06T00:00:00.000Z","completedAt":null,"scores":null,"feedback":null,"closingMessage":null,"questions":[]}"#
  }

  static func summary(id: String, status: String) -> String {
    #"{"id":""# + id
      + #"","companyName":"A","industry":"IT","jobTitle":"SE","interviewType":"hr","hiringType":"new_grad","status":""#
      + status + #"","startedAt":"2026-11-06T00:00:00.000Z","completedAt":null,"scores":null}"#
  }
}
