import Foundation

enum APIError: Error, Equatable {
  // 서버가 정해진 오류 형식으로 돌려준 경우
  case server(status: Int, code: String)
  case network
  case invalidResponse

  var code: String? {
    if case .server(_, let code) = self { return code }
    return nil
  }

  // 서버의 AI 스위치가 꺼져 있어 AI를 쓰는 요청을 거절한 경우(503 AI_DISABLED)
  var isAIDisabled: Bool { code == "AI_DISABLED" }
}

extension APIError: RepositoryError {
  var isRejected: Bool {
    if case .server(let status, _) = self { return (400..<500).contains(status) }
    return false
  }

  var isConnectionFailure: Bool { self == .network }
}

struct APIClient: Sendable {
  let baseURL: URL
  let tokenStore: DeviceTokenStore
  let session: URLSession

  init(
    baseURL: URL, tokenStore: DeviceTokenStore = DeviceTokenStore(), session: URLSession = .shared
  ) {
    self.baseURL = baseURL
    self.tokenStore = tokenStore
    self.session = session
  }

  static func fromBundle() -> APIClient {
    let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
    guard let url = URL(string: value), url.scheme != nil else {
      fatalError("API_BASE_URL is not configured")
    }
    return APIClient(baseURL: url)
  }

  func status() async throws -> ServiceStatus {
    let dto: ServiceStatusDTO = try await send("GET", "/v1/status")
    return dto.domain
  }

  func createInterview(_ body: NewInterview) async throws -> InterviewDetail {
    let dto: InterviewDetailDTO = try await send(
      "POST", "/v1/interviews", body: NewInterviewDTO(body))
    return dto.domain
  }

  func interview(id: String) async throws -> InterviewDetail {
    let dto: InterviewDetailDTO = try await send("GET", "/v1/interviews/\(id)")
    return dto.domain
  }

  func interviews(cursor: String? = nil) async throws -> InterviewPageDTO {
    var path = "/v1/interviews"
    if let cursor { path += "?cursor=\(cursor)" }
    return try await send("GET", path)
  }

  // 마지막 페이지까지 차례로 받아 이어 붙인다
  func allInterviews() async throws -> [InterviewSummary] {
    var items: [InterviewSummary] = []
    var cursor: String?
    repeat {
      let page = try await interviews(cursor: cursor)
      items += page.items.map(\.domain)
      cursor = page.nextCursor
    } while cursor != nil
    return items
  }

  func deleteInterview(id: String) async throws {
    try await sendWithoutResponse("DELETE", "/v1/interviews/\(id)")
  }

  func submitAnswer(interviewId: String, questionId: String, _ body: AnswerSubmission) async throws
    -> AnswerResult
  {
    let dto: AnswerResultDTO = try await send(
      "PUT", "/v1/interviews/\(interviewId)/questions/\(questionId)/answer",
      body: AnswerSubmissionDTO(body))
    return dto.domain
  }

  func evaluate(interviewId: String) async throws -> InterviewDetail {
    let dto: InterviewDetailDTO = try await send(
      "POST", "/v1/interviews/\(interviewId)/evaluation")
    return dto.domain
  }

  func me() async throws -> AccountStatus {
    let dto: AccountStatusDTO = try await send("GET", "/v1/me")
    return dto.domain
  }

  func signInWithApple(_ body: AppleSignInRequest) async throws -> AccountStatus {
    let dto: AccountStatusDTO = try await send(
      "POST", "/v1/auth/apple", body: AppleSignInRequestDTO(body))
    return dto.domain
  }

  // 서버가 지금 토큰을 지우므로 성공하면 새 기기 토큰으로 바꾼다
  func signOut() async throws {
    try await sendWithoutResponse("POST", "/v1/auth/logout")
    _ = try tokenStore.replaceToken()
  }

  func deleteAllData() async throws {
    try await sendWithoutResponse("DELETE", "/v1/me")
    _ = try tokenStore.replaceToken()
  }

  // 저장한 적이 없으면 nil
  func profile() async throws -> Profile? {
    let response: ProfileResponseDTO = try await send("GET", "/v1/me/profile")
    return response.profile?.domain
  }

  func saveProfile(_ profile: Profile) async throws -> Profile? {
    let response: ProfileResponseDTO = try await send(
      "PUT", "/v1/me/profile", body: ProfileDTO(profile))
    return response.profile?.domain
  }

  // 지금 앱에 들어 있는 문서 버전에 동의했다고 기록한다
  func recordConsents(_ documents: [LegalDocument]) async throws {
    _ = try await perform("POST", "/v1/me/consents", body: ConsentsRequestDTO(documents))
  }

  private struct Empty: Encodable {}
  private struct ErrorBody: Decodable {
    struct Detail: Decodable { let code: String }
    let error: Detail
  }

  private func send<Response: Decodable>(_ method: String, _ path: String) async throws -> Response
  {
    try await send(method, path, body: Optional<Empty>.none)
  }

  private func send<Body: Encodable, Response: Decodable>(
    _ method: String, _ path: String, body: Body?
  ) async throws -> Response {
    let data = try await perform(method, path, body: body)
    do {
      return try JSONDecoder().decode(Response.self, from: data)
    } catch {
      throw APIError.invalidResponse
    }
  }

  private func sendWithoutResponse(_ method: String, _ path: String) async throws {
    _ = try await perform(method, path, body: Optional<Empty>.none)
  }

  private func perform<Body: Encodable>(_ method: String, _ path: String, body: Body?) async throws
    -> Data
  {
    guard let url = URL(string: path, relativeTo: baseURL) else { throw APIError.invalidResponse }
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.timeoutInterval = 90
    request.setValue("Bearer \(try tokenStore.currentToken())", forHTTPHeaderField: "Authorization")
    if let body {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONEncoder().encode(body)
    }

    #if DEBUG
      // -apiDelay 초: 로딩 표시를 확인하려고 응답을 일부러 늦춘다
      let delay = UserDefaults.standard.double(forKey: "apiDelay")
      if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
    #endif
    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await session.data(for: request)
    } catch {
      throw APIError.network
    }
    guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
    guard (200..<300).contains(http.statusCode) else {
      let code = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error.code ?? "UNKNOWN"
      throw APIError.server(status: http.statusCode, code: code)
    }
    return data
  }
}
