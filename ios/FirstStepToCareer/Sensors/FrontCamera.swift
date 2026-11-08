import AVFoundation

// Face ID 카메라가 없는 iPhone에서 면접 준비 화면에 앞쪽 카메라 영상을 거울처럼 보여 준다.
// 미리보기만 하고 영상을 꺼내 쓰거나 저장·전송하지 않는다.
// 세션의 시작·정지는 화면을 멈추지 않도록 전용 큐에서만 한다
final class FrontCamera: @unchecked Sendable {
  static var isAvailable: Bool { device != nil }

  private static var device: AVCaptureDevice? {
    AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
  }

  let session = AVCaptureSession()
  private let queue = DispatchQueue(label: "FrontCamera")

  func start() {
    queue.async { [self] in
      if session.inputs.isEmpty { configure() }
      if !session.isRunning { session.startRunning() }
    }
  }

  func stop() {
    queue.async { [self] in
      if session.isRunning { session.stopRunning() }
    }
  }

  private func configure() {
    guard let device = Self.device, let input = try? AVCaptureDeviceInput(device: device),
      session.canAddInput(input)
    else { return }
    session.beginConfiguration()
    session.sessionPreset = .high
    session.addInput(input)
    session.commitConfiguration()
  }
}
