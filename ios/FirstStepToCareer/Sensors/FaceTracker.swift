import ARKit
import AVFoundation
import Observation

// ARKit 얼굴 추적으로 시선과 머리 방향을 읽는다. 영상은 기기 밖으로 내보내지 않는다
@MainActor
@Observable
final class FaceTracker: NSObject {
  static var isSupported: Bool { ARFaceTrackingConfiguration.isSupported }

  let session = ARSession()
  private(set) var latest: FaceSample?
  private var lastUpdate = Date.distantPast
  private var isRunning = false

  // 0.5초 넘게 갱신이 없으면 얼굴을 놓친 것으로 본다
  var currentSample: FaceSample? {
    Date().timeIntervalSince(lastUpdate) < 0.5 ? latest : nil
  }

  static func requestCameraAccess() async -> Bool {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: return true
    case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
    default: return false
    }
  }

  func start() {
    guard Self.isSupported, !isRunning else { return }
    session.delegate = self
    session.run(ARFaceTrackingConfiguration(), options: [.resetTracking, .removeExistingAnchors])
    isRunning = true
  }

  func stop() {
    guard isRunning else { return }
    session.pause()
    isRunning = false
    latest = nil
  }

  // duration 동안 10Hz로 표본을 모은다
  func collectSamples(duration: TimeInterval) async -> [FaceSample?] {
    var samples: [FaceSample?] = []
    let end = Date().addingTimeInterval(duration)
    while Date() < end {
      samples.append(currentSample)
      try? await Task.sleep(for: .milliseconds(100))
    }
    return samples
  }

  fileprivate func update(_ sample: FaceSample?) {
    latest = sample
    if sample != nil { lastUpdate = Date() }
  }

  nonisolated static func sample(from anchor: ARFaceAnchor) -> FaceSample? {
    guard anchor.isTracked else { return nil }
    let look = anchor.lookAtPoint
    let gaze = Direction(
      yaw: Double(atan2(look.x, look.z)) * 180 / .pi,
      pitch: Double(atan2(look.y, look.z)) * 180 / .pi)
    let forward = anchor.transform.columns.2
    let horizontal = (forward.x * forward.x + forward.z * forward.z).squareRoot()
    let head = Direction(
      yaw: Double(atan2(forward.x, forward.z)) * 180 / .pi,
      pitch: Double(atan2(forward.y, horizontal)) * 180 / .pi)
    return FaceSample(gaze: gaze, head: head)
  }
}

extension FaceTracker: ARSessionDelegate {
  nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    guard let anchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
    let sample = Self.sample(from: anchor)
    // ARSession은 delegateQueue를 지정하지 않으면 메인 큐에서 호출한다
    MainActor.assumeIsolated { update(sample) }
  }

  nonisolated func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
    MainActor.assumeIsolated { update(nil) }
  }
}
