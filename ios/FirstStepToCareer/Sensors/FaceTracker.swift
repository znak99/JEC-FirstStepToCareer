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

  nonisolated static func sample(from anchor: ARFaceAnchor, camera: simd_float4x4) -> FaceSample? {
    guard anchor.isTracked else { return nil }
    return FaceSample.make(
      face: anchor.transform, camera: camera, lookAtPoint: anchor.lookAtPoint,
      leftEye: anchor.leftEyeTransform, rightEye: anchor.rightEyeTransform)
  }
}

extension FaceTracker: ARSessionDelegate {
  // 얼굴과 카메라 위치를 같은 프레임에서 읽어야 휴대폰 기준 방향이 맞는다
  nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
    let anchor = frame.anchors.lazy.compactMap { $0 as? ARFaceAnchor }.first
    let sample = anchor.flatMap { Self.sample(from: $0, camera: frame.camera.transform) }
    // ARSession은 delegateQueue를 지정하지 않으면 메인 큐에서 호출한다
    MainActor.assumeIsolated { update(sample) }
  }

  nonisolated func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
    MainActor.assumeIsolated { update(nil) }
  }
}
