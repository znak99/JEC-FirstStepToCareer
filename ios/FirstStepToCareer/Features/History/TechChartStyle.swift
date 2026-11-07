import Charts
import SwiftUI

// 기록·분석 그래프 공통 디자인. 기기의 밝은/어두운 모드를 따르되 남색 바탕과 형광색 선으로 맞춘다
enum TechPalette {
  // 어두운 모드는 앱 아이콘의 밝은 파랑을 쓴다
  static let accent = adaptive(light: 0x0A7CD8, dark: 0x2392FF)
  static let accentSoft = adaptive(light: 0x6C5CE7, dark: 0x4D7CFF)
  static let positive = adaptive(light: 0x009E7A, dark: 0x2EF2B5)
  static let negative = adaptive(light: 0xE0445F, dark: 0xFF6B8A)
  static let cardTop = adaptive(light: 0xFFFFFF, dark: 0x10213F)
  static let cardBottom = adaptive(light: 0xE9F1FF, dark: 0x070F22)
  // 눈금·격자용. 투명도를 낮춰 쓴다
  static let ink = adaptive(light: 0x0B2A55, dark: 0xFFFFFF)

  static var areaFill: LinearGradient {
    LinearGradient(
      colors: [accent.opacity(0.35), accent.opacity(0)], startPoint: .top, endPoint: .bottom)
  }

  static var barFill: LinearGradient {
    LinearGradient(colors: [accentSoft, accent], startPoint: .leading, endPoint: .trailing)
  }

  private static func adaptive(light: UInt32, dark: UInt32) -> Color {
    Color(
      UIColor { traits in
        let hex = traits.userInterfaceStyle == .dark ? dark : light
        return UIColor(
          red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
          blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
      })
  }
}

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

struct TechCard<Content: View>: View {
  var title: LocalizedStringKey?
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      if let title {
        HStack(spacing: 8) {
          Capsule().fill(TechPalette.accent).frame(width: 3, height: 14)
            .shadow(color: TechPalette.accent.opacity(0.8), radius: 3)
          Text(title).font(.subheadline.weight(.semibold))
        }
      }
      content
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(TechCardBackground())
  }
}

struct TechCardBackground: View {
  // 온보딩 동의 카드처럼 테두리 없이 쓸 때 false
  var showsBorder = true

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
    shape
      .fill(
        LinearGradient(
          colors: [TechPalette.cardTop, TechPalette.cardBottom], startPoint: .topLeading,
          endPoint: .bottomTrailing)
      )
      .overlay { DotGrid().clipShape(shape) }
      .overlay {
        if showsBorder {
          shape.strokeBorder(
            LinearGradient(
              colors: [TechPalette.accent.opacity(0.55), TechPalette.accent.opacity(0.05)],
              startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }
      }
  }
}

// 앱 아이콘과 같은 도트 무늬
struct DotGrid: View {
  var body: some View {
    Canvas { context, size in
      let spacing: CGFloat = 14
      var path = Path()
      for x in stride(from: spacing / 2, to: size.width, by: spacing) {
        for y in stride(from: spacing / 2, to: size.height, by: spacing) {
          path.addEllipse(in: CGRect(x: x - 0.75, y: y - 0.75, width: 1.5, height: 1.5))
        }
      }
      context.fill(path, with: .color(TechPalette.ink.opacity(0.07)))
    }
    .allowsHitTesting(false)
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
      AxisMarks(values: [0, 25, 50, 75, 100]) {
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
          .foregroundStyle(TechPalette.ink.opacity(0.2))
        AxisValueLabel().font(.caption2.monospaced())
      }
    }
    .chartYAxis {
      AxisMarks { AxisValueLabel().font(.caption) }
    }
    .frame(height: CGFloat(rows.count) * 36 + 24)
    .reveal($progress, key: rows.map(\.value))
  }
}
