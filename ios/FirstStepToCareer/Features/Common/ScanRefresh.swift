import SwiftUI

// 당겨서 새로고침 (SITE_MAP 4절 「로딩 표시」). iOS 기본 표시는 모양을 바꿀 수 없어 직접 만든다.
// 당긴 만큼 도트가 켜지고, 기준을 넘겨 놓으면 그 자리에 멈춰 다시 불러온다.
// 성공하면 화면 위 가운데에서 연한 빛이 반원으로 퍼진다

extension View {
  // ScrollView에 붙인다. action은 다시 불러오기에 성공했으면 true를 돌려준다
  func scanRefreshable(_ action: @escaping @MainActor () async -> Bool) -> some View {
    modifier(ScanRefresh(action: action))
  }
}

private struct ScanRefresh: ViewModifier {
  let action: @MainActor () async -> Bool

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var pull: CGFloat = 0
  @State private var isDragging = false
  @State private var isArmed = false
  @State private var isRefreshing = false
  @State private var waveStart: Date?

  // 이만큼 당겼다 놓으면 다시 불러온다
  private static let threshold: CGFloat = 80
  // 불러오는 동안 내용을 이만큼 내려 둔다
  private static let holdHeight: CGFloat = 56
  // 너무 빨리 끝나도 표시가 한 번은 보이게 한다
  private static let minimumDuration = Duration.milliseconds(600)
  // 내비게이션 바의 큰 제목 줄 높이(iPhone 17, iOS 27에서 잰 값). 글자 크기 설정에 맞춰 늘린다
  private static var largeTitleHeight: CGFloat {
    UIFontMetrics(forTextStyle: .largeTitle).scaledValue(for: 52)
  }

  func body(content: Content) -> some View {
    content
      .contentMargins(.top, isRefreshing ? Self.holdHeight : 0, for: .scrollContent)
      .onScrollGeometryChange(for: CGFloat.self) { geometry in
        -(geometry.contentOffset.y + geometry.contentInsets.top)
      } action: { _, value in
        pull = max(0, value)
        guard isDragging, !isRefreshing else { return }
        if pull >= Self.threshold {
          isArmed = true
        } else if pull < Self.threshold * 0.6 {
          isArmed = false
        }
      }
      .onScrollPhaseChange { oldPhase, newPhase in
        isDragging = newPhase == .interacting
        if oldPhase == .interacting, newPhase != .interacting, isArmed {
          isArmed = false
          refresh()
        }
      }
      .sensoryFeedback(.impact(weight: .light), trigger: isArmed) { _, armed in armed }
      .overlay(alignment: .top) {
        // 당기는 동안에는 큰 제목도 함께 내려오므로 제목 위로 벌어진 자리에 둔다
        RefreshIndicator(progress: min(pull / Self.threshold, 1), isRefreshing: false)
          .frame(height: pull)
          .clipped()
          .opacity(isRefreshing ? 0 : min(1, pull / 28))
          .offset(y: -Self.largeTitleHeight)
          .allowsHitTesting(false)
      }
      .overlay(alignment: .top) {
        // 불러오는 동안에는 제목이 제자리로 돌아가고 내용만 내려가 있으므로 제목 아래에 둔다
        RefreshIndicator(progress: 1, isRefreshing: isRefreshing)
          .frame(height: Self.holdHeight)
          .offset(y: pull)
          .opacity(isRefreshing ? 1 : 0)
          .allowsHitTesting(false)
      }
      .background {
        if let waveStart {
          RefreshWave(start: waveStart, layer: .dots).ignoresSafeArea()
        }
      }
      .overlay {
        if let waveStart {
          RefreshWave(start: waveStart, layer: .light).ignoresSafeArea()
        }
      }
      .task(id: waveStart) {
        guard waveStart != nil else { return }
        try? await Task.sleep(for: .seconds(RefreshWave.duration + 0.1))
        if !Task.isCancelled { waveStart = nil }
      }
      .accessibilityAction(named: Text("再読み込み")) { refresh() }
  }

  private func refresh() {
    guard !isRefreshing else { return }
    withAnimation(.spring(duration: 0.35)) { isRefreshing = true }
    Task {
      let clock = ContinuousClock()
      let started = clock.now
      let succeeded = await action()
      let elapsed = clock.now - started
      if elapsed < Self.minimumDuration {
        try? await Task.sleep(for: Self.minimumDuration - elapsed)
      }
      withAnimation(.easeInOut(duration: 0.35)) { isRefreshing = false }
      guard succeeded, !reduceMotion else { return }
      // 접히는 움직임이 끝난 뒤 빛을 보낸다
      try? await Task.sleep(for: .milliseconds(350))
      waveStart = .now
    }
  }
}

// 당긴 자리에 놓는 도트 두 줄. 당길수록 왼쪽부터 켜지고, 불러오는 동안 빛이 반복해서 지나간다
private struct RefreshIndicator: View {
  let progress: Double
  let isRefreshing: Bool

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var start = Date()

  private static let columns = 11
  private static let rows = 2
  private static let spacing: CGFloat = 8

  var body: some View {
    TimelineView(.animation(paused: !isRefreshing || reduceMotion)) { timeline in
      let elapsed = timeline.date.timeIntervalSince(start)
      Canvas { context, size in
        draw(in: &context, size: size, elapsed: elapsed)
      }
    }
    .accessibilityHidden(true)
  }

  private func draw(in context: inout GraphicsContext, size: CGSize, elapsed: Double) {
    let spacing = Self.spacing
    let origin = CGPoint(
      x: size.width / 2 - CGFloat(Self.columns - 1) * spacing / 2,
      y: size.height / 2 - CGFloat(Self.rows - 1) * spacing / 2)
    let lit = Int((progress * Double(Self.columns)).rounded(.up))
    // 불러오는 동안 1.1초마다 왼쪽 아래에서 오른쪽 위로 빛이 지나간다
    let band: CGFloat = 26
    let span = CGFloat(Self.columns - 1) * spacing + CGFloat(Self.rows) * spacing * 0.5
    let phase = elapsed.truncatingRemainder(dividingBy: 1.1) / 1.1
    let front = -8 + (span + 16 + band) * SplashEase.easeOut(phase)
    for column in 0..<Self.columns {
      for row in 0..<Self.rows {
        var alpha = 0.18
        var radius: CGFloat = 1.1
        if isRefreshing {
          let distance =
            front - (CGFloat(column) * spacing + CGFloat(Self.rows - 1 - row) * spacing * 0.5)
          let boost = reduceMotion ? 1 : (distance >= 0 ? max(0, 1 - distance / band) : 0)
          alpha = 0.4 + 0.55 * boost
          radius = 1.3 + 1.0 * boost
        } else if column < lit {
          alpha = 0.85
          radius = 2.0
        }
        let center = CGPoint(
          x: origin.x + CGFloat(column) * spacing, y: origin.y + CGFloat(row) * spacing)
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
          with: .color(TechPalette.accent.opacity(alpha)))
      }
    }
  }
}

// 다시 불러오기에 성공한 뒤 화면 위 가운데에서 반원으로 퍼지는 연한 빛.
// 바탕의 도트(DotGrid와 같은 14pt 간격)는 내용 뒤에서 밝아지고, 아주 옅은 빛은 내용 위로 지나간다
private struct RefreshWave: View {
  enum Layer {
    case dots
    case light
  }

  let start: Date
  let layer: Layer

  static let duration = 2.0
  // 빛의 띠 두께. 화면 높이에 대한 비율
  private static let bandRatio: CGFloat = 0.94
  private static let peakOpacity = 0.03

  var body: some View {
    TimelineView(.animation) { timeline in
      let progress = min(timeline.date.timeIntervalSince(start) / Self.duration, 1)
      Canvas { context, size in
        draw(in: &context, size: size, progress: progress)
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func draw(in context: inout GraphicsContext, size: CGSize, progress: Double) {
    guard progress < 1 else { return }
    let center = CGPoint(x: size.width / 2, y: 0)
    let band = size.height * Self.bandRatio
    let farthest = hypot(size.width / 2, size.height)
    let radius = (farthest + band) * SplashEase.easeInOut(progress)
    switch layer {
    case .light:
      context.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .radialGradient(
          Gradient(stops: [
            .init(color: TechPalette.accent.opacity(0), location: 0),
            .init(color: TechPalette.accent.opacity(Self.peakOpacity), location: 0.8),
            .init(color: TechPalette.accent.opacity(0), location: 1),
          ]), center: center, startRadius: max(0, radius - band), endRadius: radius + band * 0.25))
    case .dots:
      let spacing: CGFloat = 14
      for x in stride(from: spacing / 2, to: size.width, by: spacing) {
        for y in stride(from: spacing / 2, to: size.height, by: spacing) {
          let behind = radius - hypot(x - center.x, y - center.y)
          guard behind >= 0, behind < band else { continue }
          let boost = 1 - behind / band
          let dotRadius = 0.75 + 0.84 * boost
          context.fill(
            Path(
              ellipseIn: CGRect(
                x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)),
            with: .color(TechPalette.accent.opacity(0.28 * boost)))
        }
      }
    }
  }
}
