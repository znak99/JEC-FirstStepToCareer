import SwiftUI

// 하단 탭바 (SITE_MAP 4절, T-4안). 빛나는 테두리 안에 01·02·03 번호와 아이콘, 이름을 두고,
// 선택한 탭은 네 모서리 조준 괄호가 감싼다. '동작 줄이기'가 켜져 있으면 괄호가 미끄러지지 않고 바로 옮겨 간다
struct TechTabBar: View {
  @Binding var selection: AppTab

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  static let height: CGFloat = 64
  // 화면 아래에서 띄우는 거리
  static let bottomGap: CGFloat = 6
  // 내용이 탭바에 가려지지 않게 화면 아래에 비워 둘 높이
  static let reservedHeight = height + bottomGap + 8

  // 선택한 아이콘을 채우는 그라데이션. 앱 아이콘의 파랑에서 보라로 넘어간다
  static let selectedFill = LinearGradient(
    colors: [SplashPalette.top, TechPalette.accentSoft], startPoint: .topLeading,
    endPoint: .bottomTrailing)

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    GeometryReader { proxy in
      let tabs = AppTab.allCases
      let width = proxy.size.width / CGFloat(tabs.count)
      let index = CGFloat(tabs.firstIndex(of: selection) ?? 0)
      ZStack(alignment: .topLeading) {
        AimBrackets()
          .frame(width: width - 16, height: proxy.size.height - 14)
          .offset(x: index * width + 8, y: 7)
        HStack(spacing: 0) {
          ForEach(Array(tabs.enumerated()), id: \.element) { offset, tab in
            item(tab, number: offset + 1)
              .frame(width: width, height: proxy.size.height)
          }
        }
      }
    }
    .frame(height: Self.height)
    .background(
      shape.fill(
        LinearGradient(
          colors: [TechPalette.cardTop, TechPalette.cardBottom], startPoint: .topLeading,
          endPoint: .bottomTrailing))
    )
    .overlay {
      shape.strokeBorder(
        LinearGradient(
          colors: [TechPalette.accent.opacity(0.7), TechPalette.accent.opacity(0.2)],
          startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
    }
    .shadow(color: TechPalette.accent.opacity(0.22), radius: 14)
    .animation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.3), value: selection)
  }

  private func item(_ tab: AppTab, number: Int) -> some View {
    let isOn = tab == selection
    return Button {
      selection = tab
    } label: {
      VStack(spacing: 2) {
        Text(verbatim: String(format: "%02d", number))
          .font(.system(size: 10, weight: .semibold, design: .monospaced))
          .opacity(0.6)
        icon(tab, isOn: isOn)
        Text(tab.title)
          .font(.system(size: 10, weight: .semibold))
      }
      .foregroundStyle(isOn ? TechPalette.accent : Color.secondary)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(tab.title))
    .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
  }

  @ViewBuilder
  private func icon(_ tab: AppTab, isOn: Bool) -> some View {
    let icon = TabIcon(tab: tab).frame(width: 24, height: 22)
    if isOn {
      icon
        .foregroundStyle(Self.selectedFill)
        .shadow(color: TechPalette.accent.opacity(0.7), radius: 4)
    } else {
      icon
    }
  }
}

// 탭 아이콘 (SITE_MAP 4절). 24×24 칸에 선으로 그리고, 점은 채운다
// 面接: 네 모서리 괄호 안의 사람(얼굴 조준), 記録: 점을 이은 추이선, メニュー: 세 줄
private struct TabIcon: View {
  let tab: AppTab

  var body: some View {
    ZStack {
      TabIconShape(tab: tab, part: .line)
        .stroke(style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
      TabIconShape(tab: tab, part: .dots)
    }
    .accessibilityHidden(true)
  }
}

private struct TabIconShape: Shape {
  enum Part {
    case line
    case dots
  }

  let tab: AppTab
  let part: Part

  func path(in rect: CGRect) -> Path {
    var path = Path()
    switch (tab, part) {
    case (.interview, .line):
      // 네 모서리 괄호
      path.move(to: CGPoint(x: 3, y: 7.5))
      path.addLine(to: CGPoint(x: 3, y: 4.5))
      path.addQuadCurve(to: CGPoint(x: 4.5, y: 3), control: CGPoint(x: 3, y: 3))
      path.addLine(to: CGPoint(x: 7.5, y: 3))
      path.move(to: CGPoint(x: 16.5, y: 3))
      path.addLine(to: CGPoint(x: 19.5, y: 3))
      path.addQuadCurve(to: CGPoint(x: 21, y: 4.5), control: CGPoint(x: 21, y: 3))
      path.addLine(to: CGPoint(x: 21, y: 7.5))
      path.move(to: CGPoint(x: 21, y: 16.5))
      path.addLine(to: CGPoint(x: 21, y: 19.5))
      path.addQuadCurve(to: CGPoint(x: 19.5, y: 21), control: CGPoint(x: 21, y: 21))
      path.addLine(to: CGPoint(x: 16.5, y: 21))
      path.move(to: CGPoint(x: 7.5, y: 21))
      path.addLine(to: CGPoint(x: 4.5, y: 21))
      path.addQuadCurve(to: CGPoint(x: 3, y: 19.5), control: CGPoint(x: 3, y: 21))
      path.addLine(to: CGPoint(x: 3, y: 16.5))
      // 머리와 어깨
      path.addEllipse(in: CGRect(x: 9, y: 7, width: 6, height: 6))
      path.move(to: CGPoint(x: 7.3, y: 17.8))
      path.addCurve(
        to: CGPoint(x: 12, y: 14.2), control1: CGPoint(x: 8, y: 15.5),
        control2: CGPoint(x: 9.8, y: 14.2))
      path.addCurve(
        to: CGPoint(x: 16.7, y: 17.8), control1: CGPoint(x: 14.2, y: 14.2),
        control2: CGPoint(x: 16, y: 15.5))
    case (.history, .line):
      // 점선 바닥선과 추이선
      for start in stride(from: 3.5, through: 19.5, by: 4) {
        path.move(to: CGPoint(x: start, y: 20.5))
        path.addLine(to: CGPoint(x: min(start + 1.5, 20.5), y: 20.5))
      }
      path.move(to: CGPoint(x: 4.5, y: 16))
      path.addLine(to: CGPoint(x: 9.5, y: 10.8))
      path.addLine(to: CGPoint(x: 13.5, y: 14))
      path.addLine(to: CGPoint(x: 19.5, y: 7))
    case (.history, .dots):
      for (x, y, radius) in [(4.5, 16, 1.6), (9.5, 10.8, 1.6), (13.5, 14, 1.6), (19.5, 7, 2.0)] {
        path.addEllipse(
          in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
      }
    case (.menu, .line):
      for y in [7.0, 12.0, 17.0] {
        path.move(to: CGPoint(x: 4, y: y))
        path.addLine(to: CGPoint(x: 20, y: y))
      }
    case (.interview, .dots), (.menu, .dots):
      break
    }
    // 24×24 칸을 주어진 크기에 맞춰 가운데에 둔다
    let scale = min(rect.width, rect.height) / 24
    let offset = CGPoint(
      x: rect.minX + (rect.width - 24 * scale) / 2, y: rect.minY + (rect.height - 24 * scale) / 2)
    return path.applying(
      CGAffineTransform(translationX: offset.x, y: offset.y).scaledBy(x: scale, y: scale))
  }
}

// 선택한 탭을 감싸는 네 모서리 괄호와 옅은 바탕
private struct AimBrackets: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 6, style: .continuous)
        .fill(TechPalette.accent.opacity(0.08))
        .padding(3)
      BracketCorners()
        .stroke(TechPalette.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .shadow(color: TechPalette.accent.opacity(0.9), radius: 3)
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}

private struct BracketCorners: Shape {
  func path(in rect: CGRect) -> Path {
    let length: CGFloat = 9
    var path = Path()
    // 왼쪽 위부터 시계 방향으로 모서리마다 ㄱ자 선을 긋는다
    let corners: [(CGPoint, CGFloat, CGFloat)] = [
      (CGPoint(x: rect.minX, y: rect.minY), 1, 1),
      (CGPoint(x: rect.maxX, y: rect.minY), -1, 1),
      (CGPoint(x: rect.maxX, y: rect.maxY), -1, -1),
      (CGPoint(x: rect.minX, y: rect.maxY), 1, -1),
    ]
    for (corner, dx, dy) in corners {
      path.move(to: CGPoint(x: corner.x, y: corner.y + dy * length))
      path.addLine(to: corner)
      path.addLine(to: CGPoint(x: corner.x + dx * length, y: corner.y))
    }
    return path
  }
}

#Preview {
  @Previewable @State var selection = AppTab.interview
  VStack {
    Spacer()
    TechTabBar(selection: $selection).padding(.horizontal, 22)
  }
  .background { OnboardingBackground() }
}
