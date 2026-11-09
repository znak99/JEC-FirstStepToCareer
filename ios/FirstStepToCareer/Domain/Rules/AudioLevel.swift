import Foundation

// 마이크 소리 크기를 목소리 막대 높이(0~1)로 바꾼다. 크기만 재고 소리는 저장하거나 보내지 않는다
enum AudioLevel {
  // 이보다 작으면 0(조용함), 크면 1로 본다
  static let floorDecibels: Float = -55
  static let ceilingDecibels: Float = -15

  static func rms(_ samples: UnsafeBufferPointer<Float>) -> Float {
    guard !samples.isEmpty else { return 0 }
    let sum = samples.reduce(Float(0)) { $0 + $1 * $1 }
    return (sum / Float(samples.count)).squareRoot()
  }

  static func normalized(rms: Float) -> Float {
    guard rms > 0, rms.isFinite else { return 0 }
    let decibels = 20 * log10(rms)
    let value = (decibels - floorDecibels) / (ceilingDecibels - floorDecibels)
    return min(max(value, 0), 1)
  }
}
