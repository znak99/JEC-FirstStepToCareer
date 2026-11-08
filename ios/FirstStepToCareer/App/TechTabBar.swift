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
    let image = Image(systemName: tab.systemImage)
      .font(.system(size: 19, weight: .medium))
      .frame(width: 24, height: 22)
    if isOn {
      image
        .foregroundStyle(Self.selectedFill)
        .shadow(color: TechPalette.accent.opacity(0.7), radius: 4)
    } else {
      image
    }
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
