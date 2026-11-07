import SwiftUI

// 앱을 새로 켤 때 보여 준다. 시간에 따라 그리므로 모든 움직임을 아래 시간표(초)로 정한다
enum SplashTimeline {
  static let backgroundFade = 0.25
  static let drawStagger = 0.05
  static let drawDuration = 0.6
  static let fillStart = 0.6
  static let fillDuration = 0.35
  static let scanStart = 0.85
  static let scanDuration = 1.3
  static let typeStart = 1.0
  static let typeStep = 0.13
  static let end = scanStart + scanDuration
  // 완성된 로고를 잠깐 보여 준 뒤 넘어갈지 정한다
  static let decision = end + 0.3
  // '동작 줄이기'가 켜져 있으면 처음부터 완성된 모습을 그린다
  static let complete = 10.0
}

enum SplashEase {
  static func progress(_ t: Double, _ start: Double, _ duration: Double) -> Double {
    min(max((t - start) / duration, 0), 1)
  }
  static func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
  static func easeInOut(_ x: Double) -> Double {
    x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
  }
}

// 확인용 실행 인자. 개발(Debug) 빌드에서만 읽는다
enum SplashDebug {
  #if DEBUG
    // -splashLoop YES: 끝나고 1초 뒤 다시 보여 준다
    static var loops: Bool { UserDefaults.standard.bool(forKey: "splashLoop") }
    // -splashDelay 초: 준비를 일부러 늦춰 로딩 표시를 확인한다
    static var delay: Duration { .seconds(UserDefaults.standard.double(forKey: "splashDelay")) }
  #else
    static let loops = false
    static let delay = Duration.zero
  #endif
}

struct SplashView: View {
  let hasStarted: Bool
  var onFinished: () -> Void = {}

  @Environment(\.apiClient) private var api
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var start = Date()
  @State private var model: SplashModel?

  var body: some View {
    GeometryReader { proxy in
      TimelineView(.animation) { context in
        let elapsed = context.date.timeIntervalSince(start)
        SplashFrame(
          t: reduceMotion ? SplashTimeline.complete : elapsed,
          elapsed: elapsed,
          contentOpacity: reduceMotion ? SplashEase.progress(elapsed, 0, 0.4) : 1,
          size: proxy.size,
          message: message,
          showsLoading: model?.showsLoading == true)
      }
    }
    .ignoresSafeArea()
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("就活一歩"))
    .task {
      let model = SplashModel(api: api, hasStarted: hasStarted, extraDelay: SplashDebug.delay)
      self.model = model
      await model.run()
      onFinished()
    }
  }

  private var message: LocalizedStringKey {
    switch model?.step {
    case .connecting: "サーバーに接続しています…"
    case .checkingInterview: "前回の面接を確認しています…"
    case nil: "準備しています…"
    }
  }
}

private struct SplashFrame: View {
  let t: Double
  let elapsed: Double
  let contentOpacity: Double
  let size: CGSize
  let message: LocalizedStringKey
  let showsLoading: Bool

  var body: some View {
    let logo = SplashLogo.size(width: 160)
    let logoRect = CGRect(
      x: (size.width - logo.width) / 2, y: size.height * 0.40 - logo.height / 2,
      width: logo.width, height: logo.height)
    ZStack {
      // 실행 화면의 한 가지 색에서 그라데이션으로 부드럽게 바꾼다
      SplashPalette.middle
      LinearGradient(
        colors: [SplashPalette.top, SplashPalette.middle, SplashPalette.bottom],
        startPoint: .topLeading, endPoint: .bottomTrailing
      )
      .opacity(SplashEase.progress(elapsed, 0, SplashTimeline.backgroundFade))
      Group {
        SplashScanLayer(t: t)
        SplashLogoLayer(t: t, rect: logoRect)
      }
      .opacity(contentOpacity)
      VStack(spacing: 14) {
        SplashName(t: t)
          .opacity(contentOpacity)
        Text(message)
          .font(.footnote)
          .foregroundStyle(.white.opacity(0.8))
          .opacity(showsLoading ? 1 : 0)
          .animation(.easeIn(duration: 0.3), value: showsLoading)
      }
      .frame(width: size.width)
      .position(x: size.width / 2, y: logoRect.maxY + 62)
      SplashLoadingBar(elapsed: elapsed)
        .opacity(showsLoading ? 1 : 0)
        .animation(.easeIn(duration: 0.3), value: showsLoading)
        .position(x: size.width / 2, y: size.height - 96)
    }
  }
}

// 왼쪽 아래에서 오른쪽 위로 지나가는 투명한 빛의 띠. 지나간 자리에만 도트가 생긴다
private struct SplashScanLayer: View {
  let t: Double
  private static let spacing: CGFloat = 18
  private static let bandWidth: CGFloat = 145
  // 띠가 수평에서 기운 각도. 화면 비율과 상관없이 같은 기울기로 보인다
  private static let tilt = 70.0 * Double.pi / 180

  var body: some View {
    Canvas { context, size in
      let diagonal = hypot(size.width, size.height)
      let direction = CGPoint(x: sin(Self.tilt), y: -cos(Self.tilt))
      // 왼쪽 아래 모서리(0)부터 오른쪽 위 모서리까지의 거리
      let span = size.width * direction.x - size.height * direction.y
      let scan = SplashEase.progress(t, SplashTimeline.scanStart, SplashTimeline.scanDuration)
      // 끝나면 모든 도트가 띠를 벗어나 원래 밝기가 된다
      let front = -80 + (span + 80 + Self.bandWidth) * SplashEase.easeOut(scan)
      for x in stride(from: Self.spacing / 2, to: size.width, by: Self.spacing) {
        for y in stride(from: Self.spacing / 2, to: size.height, by: Self.spacing) {
          let along = x * direction.x + (y - size.height) * direction.y
          guard along <= front else { continue }
          let boost = max(0, 1 - (front - along) / (Self.bandWidth * 0.82))
          // 아이콘처럼 오른쪽 위로 갈수록 도트가 크고 밝다
          let u = ((x / size.width) + (1 - y / size.height)) / 2
          let radius = 0.6 + 3.0 * pow(u, 1.5) + 1.0 * boost
          let alpha = 0.04 + 0.3 * u + 0.22 * boost
          context.fill(
            Path(
              ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            ),
            with: .color(.white.opacity(alpha)))
        }
      }
      guard scan > 0 && scan < 1 else { return }
      let point = CGPoint(x: direction.x * front, y: size.height + direction.y * front)
      let normal = CGPoint(x: -direction.y * diagonal, y: direction.x * diagonal)
      let behind = CGPoint(
        x: point.x - direction.x * Self.bandWidth, y: point.y - direction.y * Self.bandWidth)
      let ahead = CGPoint(x: point.x + direction.x * 24, y: point.y + direction.y * 24)
      let frontLocation = Self.bandWidth / (Self.bandWidth + 24)
      var band = Path()
      band.move(to: CGPoint(x: ahead.x - normal.x, y: ahead.y - normal.y))
      band.addLine(to: CGPoint(x: ahead.x + normal.x, y: ahead.y + normal.y))
      band.addLine(to: CGPoint(x: behind.x + normal.x, y: behind.y + normal.y))
      band.addLine(to: CGPoint(x: behind.x - normal.x, y: behind.y - normal.y))
      band.closeSubpath()
      // 경계가 드러나지 않게 앞뒤 모두 투명하게 사라진다
      context.fill(
        band,
        with: .linearGradient(
          Gradient(stops: [
            .init(color: .clear, location: 0),
            .init(color: SplashPalette.glow.opacity(0.06), location: frontLocation - 0.04),
            .init(color: .white.opacity(0.1), location: frontLocation),
            .init(color: .clear, location: 1),
          ]), startPoint: behind, endPoint: ahead))
    }
    .allowsHitTesting(false)
  }
}

// 흰 선으로 그린 뒤 안을 채운다
private struct SplashLogoLayer: View {
  let t: Double
  let rect: CGRect

  var body: some View {
    Canvas { context, _ in
      let parts = SplashLogo.parts(in: rect)
      var line = context
      line.addFilter(.shadow(color: SplashPalette.glow, radius: 6))
      for (index, part) in parts.enumerated() {
        let drawn = SplashEase.easeInOut(
          SplashEase.progress(
            t, Double(index) * SplashTimeline.drawStagger, SplashTimeline.drawDuration))
        guard drawn > 0 else { continue }
        line.stroke(
          part.trimmedPath(from: 0, to: drawn), with: .color(.white),
          style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
      }
      let filled = SplashEase.progress(t, SplashTimeline.fillStart, SplashTimeline.fillDuration)
      guard filled > 0 else { return }
      var fill = context
      fill.addFilter(.shadow(color: SplashPalette.glow.opacity(0.7), radius: 12))
      fill.opacity = filled
      for part in parts { fill.fill(part, with: .color(.white)) }
    }
    .allowsHitTesting(false)
  }
}

// 앱 이름을 타자 치듯 한 글자씩 보여 준다
private struct SplashName: View {
  let t: Double

  var body: some View {
    let characters = Array("就活一歩")
    let visible =
      t < SplashTimeline.typeStart
      ? 0 : min(Int((t - SplashTimeline.typeStart) / SplashTimeline.typeStep) + 1, characters.count)
    // 넘어가며 사라질 때까지 깜박인다
    let cursorOn = t > 0.9 && t < SplashTimeline.decision + 0.15 && Int(t / 0.25) % 2 == 0
    HStack(spacing: 6) {
      ForEach(characters.indices, id: \.self) { index in
        Text(verbatim: String(characters[index]))
          .opacity(index < visible ? 1 : 0)
          .overlay(alignment: .trailing) {
            if cursorOn && (visible == index + 1 || (visible == 0 && index == 0)) {
              Rectangle()
                .fill(SplashPalette.glow)
                .frame(width: 3, height: 34)
                .offset(x: visible == 0 ? -40 : 6)
            }
          }
      }
    }
    .font(.system(size: 34, weight: .bold))
    .foregroundStyle(.white)
    .shadow(color: SplashPalette.glow.opacity(0.6), radius: 8)
  }
}

// 가는 막대 안에서 빛이 좌우로 오간다
private struct SplashLoadingBar: View {
  let elapsed: Double

  var body: some View {
    let width: CGFloat = 120
    let segment: CGFloat = 36
    let phase = sin(2 * Double.pi * elapsed / 1.4)
    ZStack {
      Capsule().fill(.white.opacity(0.2)).frame(width: width, height: 3)
      Capsule()
        .fill(.white)
        .frame(width: segment, height: 3)
        .shadow(color: SplashPalette.glow, radius: 4)
        .offset(x: (width - segment) / 2 * phase)
    }
  }
}

#Preview {
  SplashView(hasStarted: true)
}
