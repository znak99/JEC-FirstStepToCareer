import Foundation

// 화면이 쓰는 기기 부품 약속을 이 iPhone의 실제 부품으로 채운다
struct SystemInterviewDevices: InterviewDevices {
  let capabilities: any DeviceCapabilities = SystemDeviceCapabilities()
  let audioSession: any AudioSessionControlling = SystemAudioSession()

  func makeFaceTracker() -> (any FaceTrackingPreview)? {
    FaceTracker.isSupported ? FaceTracker() : nil
  }

  func makeFrontCamera() -> (any FrontCameraPreview)? {
    FrontCamera.isAvailable ? FrontCamera() : nil
  }

  func makeSpeechRecognizer() -> any SpeechRecognizing { SpeechRecognizer() }
  func makeSpeechSynthesizer() -> any SpeechSynthesizing { SpeechSynthesizer() }
}

// 실제 카메라 부품은 화면 쪽 미리보기 약속도 따른다(필요한 값을 이미 갖고 있다)
extension FaceTracker: FaceTrackingPreview {}
extension FrontCamera: FrontCameraPreview {}
