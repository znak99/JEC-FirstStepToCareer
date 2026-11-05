import Foundation

enum InterviewRoute: Hashable {
  case setup
  case preparation(InterviewDraft)
  case session(InterviewSessionContext)
  case result(String)
}

// 면접 준비 화면에서 면접 진행 화면으로 넘기는 값. 얼굴 추적기는 같은 객체를 계속 쓴다
@MainActor
final class InterviewSessionContext: Hashable {
  let interview: InterviewDetail
  let tracker: FaceTracker?
  let baseline: FaceBaseline?

  init(interview: InterviewDetail, tracker: FaceTracker?, baseline: FaceBaseline?) {
    self.interview = interview
    self.tracker = tracker
    self.baseline = baseline
  }

  nonisolated static func == (lhs: InterviewSessionContext, rhs: InterviewSessionContext) -> Bool {
    lhs === rhs
  }

  nonisolated func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}
