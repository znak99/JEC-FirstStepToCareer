import Foundation

// 얼굴을 따라가며 시선·머리 방향을 잰다. 기기 안에서만 계산하고 영상은 내보내지 않는다
@MainActor
protocol FaceTracking: AnyObject {
  // 0.5초 넘게 갱신이 없으면 얼굴을 놓친 것으로 보고 nil
  var currentSample: FaceSample? { get }
  func start()
  func stop()
  // 기준점을 잡을 때 주어진 시간 동안 모은다. 얼굴을 놓친 순간은 nil
  func collectSamples(duration: TimeInterval) async -> [FaceSample?]
}
