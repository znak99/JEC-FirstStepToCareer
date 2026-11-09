import ARKit
import AVFoundation
import CoreImage
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

  // 면접 진행 화면의 작은 내 화면에 보여 줄 그림. ARKit 카메라는 화면 하나에만 연결할 수 있어
  // 두 번째 화면을 연결하지 않고, 받은 영상을 작게 줄여 그림으로 넘긴다. 저장하거나 보내지 않는다
  private(set) var previewImage: CGImage?
  var isPreviewing = false {
    didSet { if !isPreviewing { previewImage = nil } }
  }
  @ObservationIgnored private var previewInFlight = false
  @ObservationIgnored private var lastPreview = Date.distantPast
  @ObservationIgnored private let previewRenderer = PreviewRenderer()

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
    previewImage = nil
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

  // 1초에 15장까지만, 앞 그림을 다 만든 뒤에만 새로 만든다
  fileprivate func requestPreview(_ buffer: CVPixelBuffer) {
    guard isPreviewing, !previewInFlight, Date().timeIntervalSince(lastPreview) >= 1.0 / 15
    else { return }
    previewInFlight = true
    lastPreview = Date()
    nonisolated(unsafe) let source = buffer
    previewRenderer.render(source) { [weak self] image in
      nonisolated(unsafe) let result = image
      Task { @MainActor in
        guard let self else { return }
        self.previewInFlight = false
        if self.isPreviewing { self.previewImage = result }
      }
    }
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
    nonisolated(unsafe) let buffer = frame.capturedImage
    // ARSession은 delegateQueue를 지정하지 않으면 메인 큐에서 호출한다
    MainActor.assumeIsolated {
      update(sample)
      requestPreview(buffer)
    }
  }

  nonisolated func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
    MainActor.assumeIsolated { update(nil) }
  }
}

// 카메라 영상을 작은 그림으로 줄인다. 시간이 걸리므로 전용 큐에서 한다
private final class PreviewRenderer: @unchecked Sendable {
  private let context = CIContext()
  private let queue = DispatchQueue(label: "FaceTracker.preview", qos: .userInitiated)
  // 작은 내 화면(84pt) 3배 해상도
  private let width: CGFloat = 252

  func render(_ buffer: CVPixelBuffer, completion: @escaping @Sendable (CGImage?) -> Void) {
    nonisolated(unsafe) let source = buffer
    queue.async { [self] in
      // 앞쪽 카메라 영상은 옆으로 누워 있으므로 세우고, 거울처럼 좌우를 뒤집는다
      let image = CIImage(cvPixelBuffer: source).oriented(.leftMirrored)
      let scale = width / image.extent.width
      let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
      completion(context.createCGImage(scaled, from: scaled.extent))
    }
  }
}
