import Foundation

// 면접 준비 화면의 카메라 자리에 무엇을 보여 줄지 (SITE_MAP S-03)
enum PreparationCamera: Equatable, Sendable {
  // Face ID 카메라로 얼굴을 인식하고 시선·머리를 잰다
  case faceTracking
  // 앞쪽 카메라 영상을 거울처럼 보여 주기만 한다
  case mirror
  // 카메라를 허용하지 않았다
  case denied
  // 쓸 수 있는 앞쪽 카메라가 없다(시뮬레이터 등)
  case unavailable

  static func of(trackingSupported: Bool, hasFrontCamera: Bool, accessGranted: Bool)
    -> PreparationCamera
  {
    guard trackingSupported || hasFrontCamera else { return .unavailable }
    guard accessGranted else { return .denied }
    return trackingSupported ? .faceTracking : .mirror
  }

  // 권한을 물어볼 필요가 있는지. 카메라가 없으면 묻지 않는다
  static func needsAccess(trackingSupported: Bool, hasFrontCamera: Bool) -> Bool {
    trackingSupported || hasFrontCamera
  }
}
