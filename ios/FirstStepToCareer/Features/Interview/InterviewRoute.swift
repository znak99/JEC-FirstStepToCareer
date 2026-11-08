import Foundation

enum InterviewRoute: Hashable {
  case preparation(InterviewDraft)
  case session(InterviewSessionContext)
  case result(String)
}

// 면접 준비 화면에서 면접 진행 화면으로 넘기는 값. 준비 화면에서 켠 카메라를 같은 객체로 계속 쓴다
@MainActor
final class InterviewSessionContext: Hashable {
  let interview: InterviewDetail
  // Face ID 카메라를 쓸 때. 기준점이 없으면 작은 내 화면에 보여 주기만 하고 재지 않는다
  let tracker: FaceTracker?
  let baseline: FaceBaseline?
  // Face ID 카메라가 없는 iPhone에서 작은 내 화면에 보여 줄 앞쪽 카메라
  let frontCamera: FrontCamera?

  init(
    interview: InterviewDetail, tracker: FaceTracker?, baseline: FaceBaseline?,
    frontCamera: FrontCamera?
  ) {
    self.interview = interview
    self.tracker = tracker
    self.baseline = baseline
    self.frontCamera = frontCamera
  }

  nonisolated static func == (lhs: InterviewSessionContext, rhs: InterviewSessionContext) -> Bool {
    lhs === rhs
  }

  nonisolated func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}
