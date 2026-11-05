import Foundation

// 시선·머리가 기준점에서 벗어난 정도의 판정. 기준은 docs/system-design/DATA.md 5.2절
enum DeviationLevel: Equatable, Sendable {
  case none
  case minor
  case moderate
  case major
  case outside
}

struct DeviationThresholds: Sendable {
  let minor: Double
  let moderate: Double
  let major: Double
  let outside: Double

  // 각도 기준은 첫 값이다. 실제 iPhone으로 시험하며 조정한다
  static let gaze = DeviationThresholds(minor: 5, moderate: 10, major: 15, outside: 25)
  static let head = DeviationThresholds(minor: 5, moderate: 10, major: 20, outside: 30)

  // 얼굴을 찾지 못하면(nil) 밖으로 본다
  func level(forDegrees degrees: Double?) -> DeviationLevel {
    guard let degrees else { return .outside }
    switch degrees {
    case outside...: return .outside
    case major...: return .major
    case moderate...: return .moderate
    case minor...: return .minor
    default: return .none
    }
  }
}

extension DeductionCounts {
  mutating func add(_ level: DeviationLevel) {
    switch level {
    case .none: break
    case .minor: minor += 1
    case .moderate: moderate += 1
    case .major: major += 1
    case .outside: outside += 1
    }
  }
}

// 방향(좌우·상하 각도, 도)과 기준 방향 사이의 각도
struct Direction: Equatable, Sendable {
  var yaw: Double
  var pitch: Double

  func degrees(from base: Direction) -> Double {
    var yawDiff = (yaw - base.yaw).truncatingRemainder(dividingBy: 360)
    if yawDiff > 180 { yawDiff -= 360 }
    if yawDiff < -180 { yawDiff += 360 }
    return (yawDiff * yawDiff + (pitch - base.pitch) * (pitch - base.pitch)).squareRoot()
  }

  static func average(_ values: [Direction]) -> Direction? {
    guard !values.isEmpty else { return nil }
    let count = Double(values.count)
    return Direction(
      yaw: values.map(\.yaw).reduce(0, +) / count,
      pitch: values.map(\.pitch).reduce(0, +) / count)
  }
}

struct FaceSample: Equatable, Sendable {
  let gaze: Direction
  let head: Direction
}

struct FaceBaseline: Equatable, Sendable {
  let gaze: Direction
  let head: Direction

  // 3초 동안 모은 표본으로 기준점을 만든다. 얼굴을 놓친 프레임이 많거나 흔들림이 크면 실패한다
  static func make(from samples: [FaceSample?], maxSpreadDegrees: Double = 8) -> FaceBaseline? {
    let found = samples.compactMap { $0 }
    guard !samples.isEmpty, Double(found.count) / Double(samples.count) >= 0.8,
      let gaze = Direction.average(found.map(\.gaze)),
      let head = Direction.average(found.map(\.head))
    else { return nil }
    let spread = found.map { max($0.gaze.degrees(from: gaze), $0.head.degrees(from: head)) }.max()
    guard let spread, spread <= maxSpreadDegrees else { return nil }
    return FaceBaseline(gaze: gaze, head: head)
  }

  func levels(for sample: FaceSample?) -> (gaze: DeviationLevel, head: DeviationLevel) {
    (
      DeviationThresholds.gaze.level(forDegrees: sample.map { $0.gaze.degrees(from: gaze) }),
      DeviationThresholds.head.level(forDegrees: sample.map { $0.head.degrees(from: head) })
    )
  }
}
