import ARKit
import AVFoundation
import SwiftUI

// 카메라 영상을 화면에 비추려면 측정 약속(Domain)만으로는 부족해, 화면 쪽에서 미리보기 약속을 더한다
@MainActor
protocol FaceTrackingPreview: FaceTracking {
  // 면접 준비 화면의 큰 카메라 화면이 그리는 ARKit 세션
  var session: ARSession { get }
  // 면접 진행 화면의 작은 내 화면에 보여 줄 작은 그림. 보여 주는 동안만 만든다
  var previewImage: CGImage? { get }
  var isPreviewing: Bool { get set }
}

protocol FrontCameraPreview: FrontCameraCapturing {
  var session: AVCaptureSession { get }
}

// 면접 준비·진행 화면이 쓰는 기기 부품을 만든다. App이 실제 부품으로 채운다
@MainActor
protocol InterviewDevices {
  var capabilities: any DeviceCapabilities { get }
  var audioSession: any AudioSessionControlling { get }
  // 얼굴 추적을 지원하지 않는 iPhone이면 nil
  func makeFaceTracker() -> (any FaceTrackingPreview)?
  // 앞쪽 카메라가 없으면 nil
  func makeFrontCamera() -> (any FrontCameraPreview)?
  func makeSpeechRecognizer() -> any SpeechRecognizing
  func makeSpeechSynthesizer() -> any SpeechSynthesizing
}

extension EnvironmentValues {
  // App이 앱을 시작할 때 넣는다
  @Entry var interviewDevices: (any InterviewDevices)?
}
