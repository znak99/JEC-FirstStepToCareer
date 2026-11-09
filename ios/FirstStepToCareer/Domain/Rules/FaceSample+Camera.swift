import Foundation
import simd

// 시선과 머리 방향을 휴대폰(카메라) 기준으로 계산한다.
// 고개를 돌려도 눈이 화면을 보고 있으면 시선은 벗어나지 않고, 휴대폰과 몸을 같이 돌리면 머리는 벗어나지 않는다
extension FaceSample {
  // face·camera는 ARKit world 좌표계의 변환, lookAtPoint와 눈 변환은 얼굴 좌표계 값이다
  static func make(
    face: simd_float4x4, camera: simd_float4x4, lookAtPoint: SIMD3<Float>,
    leftEye: simd_float4x4, rightEye: simd_float4x4
  ) -> FaceSample? {
    let faceToCamera = camera.inverse * face
    let eyeCenterInFace = (position(of: leftEye) + position(of: rightEye)) / 2
    let eyeCenter = transformPoint(faceToCamera, eyeCenterInFace)
    let facePosition = position(of: faceToCamera)
    let gazeVector = transformVector(faceToCamera, lookAtPoint - eyeCenterInFace)
    // 얼굴 좌표계의 +z는 얼굴 앞쪽을 향한다
    let headVector = transformVector(faceToCamera, SIMD3(0, 0, 1))
    guard let gaze = direction(of: gazeVector, from: eyeCenter),
      let head = direction(of: headVector, from: facePosition)
    else { return nil }
    return FaceSample(gaze: gaze, head: head)
  }

  // origin에서 카메라(원점)를 바라보는 방향을 0도로 두고, 화면 좌우(yaw)·상하(pitch) 각도로 나눈다
  private static func direction(of vector: SIMD3<Float>, from origin: SIMD3<Float>) -> Direction? {
    let distance = simd_length(origin)
    guard distance > 0.01, simd_length(vector) > 0 else { return nil }
    let toward = -origin / distance
    // ARKit 카메라 좌표계는 가로 화면 기준이라, 세로로 든 화면의 오른쪽은 +y, 위쪽은 -x다
    let right = perpendicular(SIMD3(0, 1, 0), to: [toward])
    let up = perpendicular(SIMD3(-1, 0, 0), to: [toward, right])
    let forward = Double(simd_dot(vector, toward))
    let horizontal = Double(simd_dot(vector, right))
    let vertical = Double(simd_dot(vector, up))
    return Direction(
      yaw: atan2(horizontal, forward) * 180 / .pi,
      pitch: atan2(vertical, (forward * forward + horizontal * horizontal).squareRoot()) * 180 / .pi
    )
  }

  // 기기에 고정된 축을 주어진 단위 벡터들과 직교하도록 다듬는다
  private static func perpendicular(_ axis: SIMD3<Float>, to units: [SIMD3<Float>]) -> SIMD3<Float>
  {
    let projected = units.reduce(axis) { $0 - simd_dot($0, $1) * $1 }
    return simd_normalize(projected)
  }

  private static func position(of transform: simd_float4x4) -> SIMD3<Float> {
    SIMD3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
  }

  private static func transformPoint(_ transform: simd_float4x4, _ point: SIMD3<Float>) -> SIMD3<
    Float
  > {
    let result = transform * SIMD4(point, 1)
    return SIMD3(result.x, result.y, result.z)
  }

  private static func transformVector(_ transform: simd_float4x4, _ vector: SIMD3<Float>) -> SIMD3<
    Float
  > {
    let result = transform * SIMD4(vector, 0)
    return SIMD3(result.x, result.y, result.z)
  }
}
