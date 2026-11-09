import Foundation

// 시간에 따라 직접 그리는 움직임(스플래시·로딩 표시·당겨서 새로고침)이 함께 쓰는 진행도와 가속 곡선
enum Easing {
  static func progress(_ t: Double, _ start: Double, _ duration: Double) -> Double {
    min(max((t - start) / duration, 0), 1)
  }
  static func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
  static func easeInOut(_ x: Double) -> Double {
    x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
  }
}
