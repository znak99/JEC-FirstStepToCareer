import Foundation
import Testing
import simd

@testable import FirstStepToCareer

// 휴대폰(카메라) 기준 시선·머리 계산. 카메라는 원점, 얼굴은 35cm 앞에 있다
struct FaceSampleCameraTests {
  private let eyeCenterInFace = SIMD3<Float>(0, 0.03, 0.02)
  private let leftEye = Self.translation(SIMD3(0.03, 0.03, 0.02))
  private let rightEye = Self.translation(SIMD3(-0.03, 0.03, 0.02))

  // 얼굴의 +z(앞쪽)가 카메라를 향하도록 y축으로 180도 돌린 자세에서, 고개를 headYaw도 더 돌린다
  private func face(headYaw: Float = 0, transform: simd_float4x4 = matrix_identity_float4x4)
    -> simd_float4x4
  {
    transform * Self.translation(SIMD3(0, -0.03, 0.37)) * Self.rotationY(.pi + radians(headYaw))
  }

  // 두 눈 가운데에서 world 좌표 target을 바라볼 때의 lookAtPoint(얼굴 좌표계)
  private func lookAt(_ target: SIMD3<Float>, face: simd_float4x4) -> SIMD3<Float> {
    let eye = face * SIMD4(eyeCenterInFace, 1)
    let direction = simd_normalize(target - SIMD3(eye.x, eye.y, eye.z))
    let inFace = face.inverse * SIMD4(direction, 0)
    return eyeCenterInFace + SIMD3(inFace.x, inFace.y, inFace.z) * 0.5
  }

  private func sample(face: simd_float4x4, camera: simd_float4x4, target: SIMD3<Float>)
    -> FaceSample?
  {
    FaceSample.make(
      face: face, camera: camera, lookAtPoint: lookAt(target, face: face),
      leftEye: leftEye, rightEye: rightEye)
  }

  private var baseline: FaceSample {
    sample(face: face(), camera: matrix_identity_float4x4, target: .zero)!
  }

  @Test func headTurnWithEyesOnPhoneMovesOnlyHead() throws {
    let turned = try #require(
      sample(face: face(headYaw: 20), camera: matrix_identity_float4x4, target: .zero))
    #expect(abs(turned.head.degrees(from: baseline.head) - 20) < 1)
    #expect(turned.gaze.degrees(from: baseline.gaze) < 0.5)
  }

  @Test func eyesOffPhoneMovesOnlyGaze() throws {
    // 눈 위치(카메라에서 35cm)에서 옆으로 15도 벗어난 곳을 본다
    let offset = SIMD3<Float>(0.35 * tan(radians(15)), 0, 0)
    let looking = try #require(
      sample(face: face(), camera: matrix_identity_float4x4, target: offset))
    #expect(abs(looking.gaze.degrees(from: baseline.gaze) - 15) < 0.5)
    #expect(looking.head.degrees(from: baseline.head) < 0.01)
  }

  @Test func turningPhoneAndBodyTogetherChangesNothing() throws {
    let moved = Self.translation(SIMD3(0.1, 0.2, -0.05)) * Self.rotationY(radians(30))
    let together = try #require(
      sample(
        face: face(transform: moved), camera: moved,
        target: SIMD3(moved.columns.3.x, moved.columns.3.y, moved.columns.3.z)))
    #expect(together.head.degrees(from: baseline.head) < 0.1)
    #expect(together.gaze.degrees(from: baseline.gaze) < 0.1)
  }

  @Test func facingPhoneIsNearZero() {
    #expect(baseline.gaze.degrees(from: Direction(yaw: 0, pitch: 0)) < 0.5)
    // 얼굴 중심은 눈보다 3cm 아래라 카메라 방향과 약간 어긋난다
    #expect(baseline.head.degrees(from: Direction(yaw: 0, pitch: 0)) < 5)
  }

  private func radians(_ degrees: Float) -> Float { degrees * .pi / 180 }

  private static func translation(_ value: SIMD3<Float>) -> simd_float4x4 {
    var matrix = matrix_identity_float4x4
    matrix.columns.3 = SIMD4(value, 1)
    return matrix
  }

  private static func rotationY(_ angle: Float) -> simd_float4x4 {
    simd_float4x4(simd_quatf(angle: angle, axis: SIMD3(0, 1, 0)))
  }
}
