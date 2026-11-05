import Testing

@testable import FirstStepToCareer

struct DeviationTests {
  @Test(
    arguments: [
      (nil, DeviationLevel.outside), (0, .none), (4.9, .none), (5, .minor), (9.9, .minor),
      (10, .moderate), (15, .major), (24.9, .major), (25, .outside),
    ] as [(Double?, DeviationLevel)])
  func gazeLevels(degrees: Double?, expected: DeviationLevel) {
    #expect(DeviationThresholds.gaze.level(forDegrees: degrees) == expected)
  }

  @Test(
    arguments: [
      (nil, DeviationLevel.outside), (4.9, .none), (5, .minor), (10, .moderate), (19.9, .moderate),
      (20, .major), (29.9, .major), (30, .outside),
    ] as [(Double?, DeviationLevel)])
  func headLevels(degrees: Double?, expected: DeviationLevel) {
    #expect(DeviationThresholds.head.level(forDegrees: degrees) == expected)
  }

  @Test func countsAddUp() {
    var counts = DeductionCounts()
    for level in [DeviationLevel.none, .minor, .minor, .moderate, .major, .outside] {
      counts.add(level)
    }
    #expect(counts == DeductionCounts(minor: 2, moderate: 1, major: 1, outside: 1))
  }

  @Test func directionDistanceWrapsAround() {
    let a = Direction(yaw: 179, pitch: 0)
    let b = Direction(yaw: -179, pitch: 0)
    #expect(abs(a.degrees(from: b) - 2) < 0.0001)
    #expect(
      abs(Direction(yaw: 3, pitch: 4).degrees(from: Direction(yaw: 0, pitch: 0)) - 5) < 0.0001)
  }

  private func sample(_ yaw: Double) -> FaceSample {
    FaceSample(gaze: Direction(yaw: yaw, pitch: 0), head: Direction(yaw: yaw, pitch: 0))
  }

  @Test func baselineAveragesSteadySamples() throws {
    let baseline = try #require(FaceBaseline.make(from: [sample(1), sample(3), sample(2)]))
    #expect(baseline.gaze == Direction(yaw: 2, pitch: 0))
  }

  @Test func baselineFailsWhenFaceIsLostOften() {
    let samples: [FaceSample?] = [sample(0), nil, sample(0), nil, sample(0)]
    #expect(FaceBaseline.make(from: samples) == nil)
  }

  @Test func baselineFailsWhenShaky() {
    #expect(FaceBaseline.make(from: [sample(0), sample(20), sample(0)]) == nil)
  }

  @Test func baselineFailsWithoutSamples() {
    #expect(FaceBaseline.make(from: []) == nil)
  }

  @Test func levelsAreRelativeToBaseline() throws {
    let baseline = try #require(FaceBaseline.make(from: [sample(30), sample(30)]))
    let levels = baseline.levels(for: sample(42))
    #expect(levels.gaze == .moderate)
    #expect(levels.head == .moderate)
    let missing = baseline.levels(for: nil)
    #expect(missing.gaze == .outside)
    #expect(missing.head == .outside)
  }
}
