import Charts
import SwiftUI

// 점수 그래프 부품. 기록·분석·면접 결과 화면이 함께 쓴다

extension Animation {
  static let chartReveal = Animation.spring(duration: 1.1, bounce: 0.15)
}

// 0에서 1로 차오르는 진행도. '동작 줄이기'가 켜져 있으면 바로 1이 된다
struct RevealProgress<Key: Equatable>: ViewModifier {
  let key: Key
  @Binding var progress: Double
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func body(content: Content) -> some View {
    content.task(id: key) {
      if reduceMotion {
        progress = 1
        return
      }
      if progress > 0 {
        progress = 0
        // 0인 상태가 한 번 그려진 뒤 차오르게 한다
        try? await Task.sleep(for: .milliseconds(30))
      }
      withAnimation(.chartReveal) { progress = 1 }
    }
  }
}

extension View {
  func reveal<Key: Equatable>(_ progress: Binding<Double>, key: Key) -> some View {
    modifier(RevealProgress(key: key, progress: progress))
  }
}

// 0~100점을 둥근 게이지로 보여 준다
struct ScoreGauge: View {
  let value: Double?
  @State private var progress = 0.0

  var body: some View {
    let fraction = min(max((value ?? 0) / 100, 0), 1) * progress
    ZStack {
      Circle().stroke(TechPalette.ink.opacity(0.08), lineWidth: 10)
      Circle()
        .inset(by: 14)
        .stroke(TechPalette.ink.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
      Circle()
        .trim(from: 0, to: fraction)
        .stroke(
          AngularGradient(
            colors: [TechPalette.accent, TechPalette.accentSoft, TechPalette.accent],
            center: .center),
          style: StrokeStyle(lineWidth: 10, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .shadow(color: TechPalette.accent.opacity(0.7), radius: 6)
        // 0일 때 둥근 끝만 점처럼 남지 않게 한다
        .opacity(fraction > 0 ? 1 : 0)
      VStack(spacing: 0) {
        if let value {
          Text(verbatim: String(format: "%.1f", value * progress))
            .font(.system(size: 30, weight: .semibold, design: .monospaced))
            .contentTransition(.numericText(value: value * progress))
            .minimumScaleFactor(0.5)
          Text("点").font(.caption2).foregroundStyle(.secondary)
        } else {
          Text("評価なし").font(.caption).foregroundStyle(.secondary)
        }
      }
      .padding(18)
    }
    .aspectRatio(1, contentMode: .fit)
    .reveal($progress, key: value)
  }
}

// 항목별 0~100점을 거미줄 모양으로 보여 준다. 항목이 3개 이상일 때 쓴다
struct RadarChart: View {
  struct Axis: Identifiable {
    let id: ScoreMetric
    let label: String
    let value: Double
    let tint: Color
  }

  let axes: [Axis]
  @State private var progress = 0.0

  var body: some View {
    GeometryReader { proxy in
      let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
      let radius = min(proxy.size.width, proxy.size.height) / 2 - 30
      ZStack {
        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { level in
          polygon(center: center, radius: radius) { _ in level }
            .stroke(
              TechPalette.ink.opacity(level == 1 ? 0.25 : 0.12),
              style: StrokeStyle(lineWidth: 1, dash: level == 1 ? [] : [2, 3]))
        }
        Path { path in
          for index in axes.indices {
            path.move(to: center)
            path.addLine(to: point(index, center: center, radius: radius))
          }
        }
        .stroke(TechPalette.ink.opacity(0.12), lineWidth: 1)
        let values = polygon(center: center, radius: radius) { axes[$0].value / 100 * progress }
        values.fill(TechPalette.areaFill)
        values.stroke(TechPalette.accent, lineWidth: 2)
          .shadow(color: TechPalette.accent.opacity(0.8), radius: 6)
        ForEach(Array(axes.enumerated()), id: \.element.id) { index, axis in
          Circle()
            .fill(axis.tint)
            .frame(width: 9, height: 9)
            .shadow(color: axis.tint, radius: 4)
            .position(
              point(index, center: center, radius: radius * axis.value / 100 * progress))
          VStack(spacing: 1) {
            Text(axis.label).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            Text(verbatim: String(format: "%.1f", axis.value))
              .font(.caption.monospaced().weight(.semibold))
              .foregroundStyle(axis.tint)
          }
          .fixedSize()
          .position(point(index, center: center, radius: radius + 20))
        }
      }
    }
    .frame(height: 260)
    .reveal($progress, key: axes.map(\.value))
  }

  private func point(_ index: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
    let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(axes.count)
    return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
  }

  private func polygon(center: CGPoint, radius: CGFloat, scale: (Int) -> Double) -> Path {
    Path { path in
      for index in axes.indices {
        let target = point(index, center: center, radius: radius * scale(index))
        if index == 0 { path.move(to: target) } else { path.addLine(to: target) }
      }
      path.closeSubpath()
    }
  }
}

// 가로 막대 비교. 값이 없는 행은 막대 없이 설명만 보여 준다
struct TechBarChart: View {
  struct Row: Identifiable {
    let label: String
    let value: Double?
    let caption: String
    var tint: Color?
    var id: String { label }
  }

  let rows: [Row]
  @State private var progress = 0.0

  var body: some View {
    Chart(rows) { row in
      BarMark(
        x: .value("点", (row.value ?? 0) * progress), y: .value("区分", row.label),
        height: .fixed(12)
      )
      .foregroundStyle(row.tint.map { AnyShapeStyle($0) } ?? AnyShapeStyle(TechPalette.barFill))
      .cornerRadius(6)
      .annotation(position: .trailing, spacing: 6) {
        Text(verbatim: row.caption)
          .font(.caption.monospacedDigit())
          .foregroundStyle(row.value == nil ? .secondary : .primary)
      }
    }
    .chartXScale(domain: 0...100)
    .chartXAxis {
      AxisMarks(values: [0, 25, 50, 75, 100]) { value in
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
          .foregroundStyle(TechPalette.ink.opacity(0.2))
        // 오른쪽 끝 「100」은 가운데 맞춤이면 그래프 밖으로 나가 사라지므로 오른쪽에 맞춘다
        AxisValueLabel(anchor: value.index == value.count - 1 ? .topTrailing : .top)
          .font(.caption2.monospaced())
      }
    }
    .chartYAxis {
      AxisMarks { AxisValueLabel().font(.caption) }
    }
    .frame(height: CGFloat(rows.count) * 36 + 24)
    .reveal($progress, key: rows.map(\.value))
  }
}
