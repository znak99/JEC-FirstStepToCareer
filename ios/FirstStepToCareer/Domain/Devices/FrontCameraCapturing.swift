import Foundation

// 얼굴 추적을 못 하는 iPhone에서 앞쪽 카메라를 켜고 끈다. 화면에 비추기만 하고 재지 않는다
protocol FrontCameraCapturing: AnyObject, Sendable {
  func start()
  func stop()
}
