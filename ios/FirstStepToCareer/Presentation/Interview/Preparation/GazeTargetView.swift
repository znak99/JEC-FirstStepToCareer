import SwiftUI

// 시선과 머리가 기준점에서 몇 도 벗어났는지 과녁 모양으로 보여 준다. 원은 감점 기준 각도다
struct GazeTargetView: View {
  let tracker: any FaceTracking
  let baseline: FaceBaseline?

  var body: some View {
    // 얼굴을 놓쳤을 때도 표시가 바뀌도록 주기적으로 다시 그린다
    TimelineView(.periodic(from: .now, by: 0.1)) { _ in
      let sample = tracker.currentSample
      VStack(spacing: 6) {
        HStack(spacing: 12) {
          DeviationTarget(
            title: "視線", thresholds: .gaze, color: .yellow,
            current: sample?.gaze, base: baseline?.gaze ?? Direction(yaw: 0, pitch: 0))
          DeviationTarget(
            title: "頭", thresholds: .head, color: .cyan,
            current: sample?.head, base: baseline?.head ?? Direction(yaw: 0, pitch: 0))
        }
        if sample == nil {
          Text("顔を認識できません").font(.caption.bold()).foregroundStyle(.red)
        } else if baseline == nil {
          Text("基準点を設定すると、ずれの角度を表示します").font(.caption2)
        }
      }
      .padding(10)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
  }
}

private struct DeviationTarget: View {
  let title: LocalizedStringKey
  let thresholds: DeviationThresholds
  let color: Color
  let current: Direction?
  let base: Direction

  private let size: CGFloat = 110

  var body: some View {
    let degrees = current.map { $0.degrees(from: base) }
    VStack(spacing: 4) {
      Text(title).font(.caption.bold())
      ZStack {
        ForEach(
          [thresholds.minor, thresholds.moderate, thresholds.major, thresholds.outside], id: \.self
        ) {
          threshold in
          Circle()
            .stroke(.primary.opacity(threshold == thresholds.outside ? 0.6 : 0.25), lineWidth: 1)
            .frame(width: radius(threshold) * 2, height: radius(threshold) * 2)
        }
        if let current {
          Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .offset(offset(current))
        }
      }
      .frame(width: size, height: size)
      Text(degrees.map { String(format: "%.1f°", $0) } ?? "—")
        .font(.caption.monospacedDigit())
      Text(levelLabel(thresholds.level(forDegrees: degrees))).font(.caption2)
    }
  }

  // 바깥 원(범위 밖 기준)이 과녁 가장자리에 오도록 맞춘다
  private func radius(_ degrees: Double) -> CGFloat {
    size / 2 * CGFloat(degrees / thresholds.outside)
  }

  private func offset(_ direction: Direction) -> CGSize {
    var yaw = (direction.yaw - base.yaw).truncatingRemainder(dividingBy: 360)
    if yaw > 180 { yaw -= 360 }
    if yaw < -180 { yaw += 360 }
    let limit = thresholds.outside
    return CGSize(
      width: radius(min(max(yaw, -limit), limit)),
      height: -radius(min(max(direction.pitch - base.pitch, -limit), limit)))
  }

  private func levelLabel(_ level: DeviationLevel) -> LocalizedStringKey {
    switch level {
    case .none: "ずれなし"
    case .minor: "小さいずれ"
    case .moderate: "中くらいのずれ"
    case .major: "大きいずれ"
    case .outside: "範囲外"
    }
  }
}
