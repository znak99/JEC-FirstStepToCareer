import Foundation
import Testing

@testable import FirstStepToCareer

struct AudioLevelTests {
  @Test func rmsOfSamples() {
    let samples: [Float] = [0.5, -0.5, 0.5, -0.5]
    let rms = samples.withUnsafeBufferPointer { AudioLevel.rms($0) }
    #expect(abs(rms - 0.5) < 0.0001)
    #expect([Float]().withUnsafeBufferPointer { AudioLevel.rms($0) } == 0)
  }

  @Test func silenceIsZeroAndLoudIsOne() {
    #expect(AudioLevel.normalized(rms: 0) == 0)
    #expect(AudioLevel.normalized(rms: 0.0001) == 0)
    #expect(AudioLevel.normalized(rms: 1) == 1)
    #expect(AudioLevel.normalized(rms: .nan) == 0)
  }

  @Test func middleOfRangeIsHalf() {
    // -35dB는 -55dB와 -15dB의 가운데다
    let rms = Float(pow(10, -35.0 / 20))
    #expect(abs(AudioLevel.normalized(rms: rms) - 0.5) < 0.001)
  }
}
