import Foundation

// 프로필·동의 API가 주고받는 JSON 그대로의 형식. 이 iPhone에 프로필 사본을 둘 때도 같은 모양을 쓴다.
// 빈 항목은 키를 빼고 보낸다(서버는 빼거나 null이면 비운 것으로 본다)
struct ProfileDTO: Codable, Equatable {
  let nickname: String
  let hiringType: HiringType?
  let industry: String?
  let jobTitle: String?

  init(_ value: Profile) {
    nickname = value.nickname
    hiringType = value.hiringType
    industry = value.industry
    jobTitle = value.jobTitle
  }

  var domain: Profile {
    Profile(saved: nickname, hiringType: hiringType, industry: industry, jobTitle: jobTitle)
  }
}

// 저장한 적이 없으면 profile이 null
struct ProfileResponseDTO: Codable, Equatable {
  let profile: ProfileDTO?
}

struct ConsentRecordDTO: Codable, Equatable {
  let document: String
  let version: String
}

struct ConsentsRequestDTO: Codable, Equatable {
  let consents: [ConsentRecordDTO]

  // 지금 앱에 들어 있는 문서 버전으로 만든다
  init(_ documents: [LegalDocument]) {
    consents = documents.map { ConsentRecordDTO(document: $0.rawValue, version: $0.version) }
  }
}
