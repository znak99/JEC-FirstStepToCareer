import SwiftUI

// 로딩 표시 공통 부품 (SITE_MAP 4절 「로딩 표시」).
// '동작 줄이기'가 켜져 있으면 움직임을 멈춘 모습으로 보여 준다

// MARK: 스켈레톤

private struct SkeletonMaskKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  // 스캔 빛을 상자 모양으로 잘라 낼 때는 상자를 불투명하게 그린다
  fileprivate var isSkeletonMask: Bool {
    get { self[SkeletonMaskKey.self] }
    set { self[SkeletonMaskKey.self] = newValue }
  }
}

// 내용이 들어올 자리에 두는 빈 상자. width가 nil이면 가로로 가득 찬다
struct SkeletonBox: View {
  var width: CGFloat?
  let height: CGFloat
  var cornerRadius: CGFloat = 8

  @Environment(\.isSkeletonMask) private var isMask

  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      .fill(isMask ? Color.black : TechPalette.ink.opacity(0.06))
      .frame(width: width, height: height)
      .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
  }
}

// 빈 상자들 위로 비스듬한 빛이 지나가고, 상자 안의 도트만 밝아진다
struct DotScanSkeleton<Content: View>: View {
  var spacing: CGFloat = 9
  var bandWidth: CGFloat = 110
  @ViewBuilder let content: Content

  var body: some View {
    content
      .overlay {
        DotScanLayer(spacing: spacing, bandWidth: bandWidth)
          .mask { content.environment(\.isSkeletonMask, true) }
      }
      .allowsHitTesting(false)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text("読み込み中"))
  }
}

private struct DotScanLayer: View {
  let spacing: CGFloat
  let bandWidth: CGFloat

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var start = Date()

  private static let sweep = 1.8
  private static let cycle = 2.3
  // 스플래시와 같은 기울기(수평에서 60°)로 왼쪽 아래에서 오른쪽 위로 지나간다
  private static let direction = CGPoint(x: sin(Double.pi / 3), y: -cos(Double.pi / 3))

  var body: some View {
    TimelineView(.animation(paused: reduceMotion)) { timeline in
      let elapsed = timeline.date.timeIntervalSince(start)
      Canvas { context, size in
        draw(in: &context, size: size, elapsed: elapsed)
      }
    }
  }

  private func draw(in context: inout GraphicsContext, size: CGSize, elapsed: Double) {
    let direction = Self.direction
    let span = size.width * direction.x - size.height * direction.y
    let progress =
      reduceMotion ? 1 : min(elapsed.truncatingRemainder(dividingBy: Self.cycle) / Self.sweep, 1)
    let isScanning = progress < 1
    let front = -bandWidth * 0.3 + (span + bandWidth * 1.3) * Easing.easeOut(progress)
    if isScanning {
      let point = CGPoint(x: direction.x * front, y: size.height + direction.y * front)
      let behind = CGPoint(
        x: point.x - direction.x * bandWidth, y: point.y - direction.y * bandWidth)
      let ahead = CGPoint(x: point.x + direction.x * 16, y: point.y + direction.y * 16)
      context.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .linearGradient(
          Gradient(stops: [
            .init(color: TechPalette.accent.opacity(0), location: 0),
            .init(color: TechPalette.accent.opacity(0.16), location: 0.85),
            .init(color: TechPalette.accent.opacity(0), location: 1),
          ]), startPoint: behind, endPoint: ahead))
    }
    // 띠 밖의 도트는 한 번에 그려 계산을 줄인다
    var resting = Path()
    for x in stride(from: spacing / 2, to: size.width, by: spacing) {
      for y in stride(from: spacing / 2, to: size.height, by: spacing) {
        let distance = front - (x * direction.x + (y - size.height) * direction.y)
        let boost = isScanning && distance >= 0 ? max(0, 1 - distance / bandWidth) : 0
        if boost < 0.02 {
          resting.addEllipse(in: CGRect(x: x - 0.8, y: y - 0.8, width: 1.6, height: 1.6))
        } else {
          let radius = 0.8 + 1.4 * boost
          context.fill(
            Path(
              ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            ),
            with: .color(TechPalette.accent.opacity(0.16 + 0.7 * boost)))
        }
      }
    }
    context.fill(resting, with: .color(TechPalette.accent.opacity(0.16)))
  }
}

// MARK: 작은 표시

// 차례로 튀는 점 3개. 버튼 안이나 말풍선 안에 둔다
struct LoadingDots: View {
  var color: Color = TechPalette.accent
  var size: CGFloat = 7

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    TimelineView(.animation(paused: reduceMotion)) { timeline in
      let seconds = timeline.date.timeIntervalSinceReferenceDate
      HStack(spacing: size * 0.6) {
        ForEach(0..<3, id: \.self) { index in
          let lift = reduceMotion ? 0.5 : Self.lift(seconds - Double(index) * 0.15)
          Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(0.35 + 0.65 * lift)
            .offset(y: -size * 0.6 * lift)
        }
      }
      .padding(.top, size * 0.6)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("読み込み中"))
  }

  // 1초마다 0에서 1로 올랐다가 내려와 잠깐 쉰다
  private static func lift(_ seconds: Double) -> Double {
    let phase = seconds - floor(seconds)
    return phase < 0.8 ? sin(phase / 0.8 * Double.pi) : 0
  }
}

// 상태 점과 같은 자리에서 고리가 퍼진다
struct PulseDot: View {
  var color: Color = TechPalette.accent

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private let size: CGFloat = 12

  var body: some View {
    TimelineView(.animation(paused: reduceMotion)) { timeline in
      let seconds = timeline.date.timeIntervalSinceReferenceDate
      let progress = reduceMotion ? 0.4 : seconds.truncatingRemainder(dividingBy: 1.4) / 1.4
      ZStack {
        Circle()
          .stroke(color.opacity(0.8 * (1 - progress)), lineWidth: 2)
          .frame(width: size * (1 + 2 * progress), height: size * (1 + 2 * progress))
        Circle()
          .fill(color)
          .frame(width: size, height: size)
          .shadow(color: color, radius: 6)
      }
    }
    .frame(width: size * 3, height: size * 3)
    .accessibilityHidden(true)
  }
}

extension View {
  // 천천히 깜박인다. delay로 여러 개를 차례로 깜박이게 한다
  func loadingBlink(delay: Double = 0) -> some View {
    modifier(LoadingBlink(delay: delay))
  }
}

private struct LoadingBlink: ViewModifier {
  let delay: Double

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func body(content: Content) -> some View {
    TimelineView(.animation(paused: reduceMotion)) { timeline in
      let seconds = timeline.date.timeIntervalSinceReferenceDate - delay
      content.opacity(
        reduceMotion ? 0.6 : 0.25 + 0.75 * (0.5 + 0.5 * cos(2 * Double.pi * seconds / 1.1)))
    }
  }
}

// 정해진 시간 동안 고리가 한 바퀴 차오른다. 남은 시간을 알려 주는 표시라 '동작 줄이기'에서도 움직인다
struct CountdownRing: View {
  let duration: Double
  var lineWidth: CGFloat = 3

  @State private var progress = 0.0

  var body: some View {
    ZStack {
      Circle().stroke(TechPalette.ink.opacity(0.12), lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(TechPalette.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
    .padding(lineWidth / 2)
    .onAppear { withAnimation(.linear(duration: duration)) { progress = 1 } }
    .accessibilityHidden(true)
  }
}

// 처리 중 덮개 가운데에서 도는 고리
struct LoadingRing: View {
  var size: CGFloat = 34
  var lineWidth: CGFloat = 3.5

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    TimelineView(.animation(paused: reduceMotion)) { timeline in
      let seconds = timeline.date.timeIntervalSinceReferenceDate
      let turn = reduceMotion ? 0 : seconds.truncatingRemainder(dividingBy: 0.9) / 0.9
      ZStack {
        Circle().stroke(TechPalette.ink.opacity(0.12), lineWidth: lineWidth)
        Circle()
          .trim(from: 0, to: 0.3)
          .stroke(TechPalette.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
          .rotationEffect(.degrees(360 * turn))
      }
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

// MARK: 처리 중 덮개

extension View {
  // 저장·로그인·삭제 중에 화면을 옅게 덮는다. 0.3초 안에 끝나면 번쩍이지 않게 보여 주지 않는다
  func loadingOverlay(_ isPresented: Bool, message: LocalizedStringKey) -> some View {
    modifier(LoadingOverlay(isPresented: isPresented, message: message))
  }
}

private struct LoadingOverlay: ViewModifier {
  let isPresented: Bool
  let message: LocalizedStringKey

  @State private var isVisible = false
  // 사라지는 동안 문구가 바뀌지 않게 나타날 때의 문구를 붙잡아 둔다
  @State private var shownMessage: LocalizedStringKey?

  func body(content: Content) -> some View {
    content
      .overlay {
        if isVisible {
          ZStack {
            Color.black.opacity(0.25)
              .ignoresSafeArea()
              .contentShape(Rectangle())
            VStack(spacing: 12) {
              LoadingRing()
              if let shownMessage {
                Text(shownMessage)
                  .font(.subheadline.weight(.semibold))
              }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 22)
            .background(TechCardBackground(showsBorder: false))
            .shadow(color: .black.opacity(0.15), radius: 20)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isModal)
          }
          .transition(.opacity)
        }
      }
      .task(id: isPresented) {
        guard isPresented else {
          withAnimation(.easeOut(duration: 0.2)) { isVisible = false }
          return
        }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        shownMessage = message
        withAnimation(.easeIn(duration: 0.2)) { isVisible = true }
      }
  }
}
