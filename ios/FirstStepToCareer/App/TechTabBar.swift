import SwiftUI

// 하단 탭바 (SITE_MAP 4절). 빛나는 테두리 안에 아이콘과 이름을 두고,
// 선택한 탭은 파란 글씨와 그라데이션 아이콘으로 보여 준다
struct TechTabBar: View {
  @Binding var selection: AppTab
  // 이미 고른 탭을 다시 눌렀을 때. 그 탭의 첫 화면으로 돌아간다
  var onReselect: (AppTab) -> Void = { _ in }

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  static let height: CGFloat = 64
  // 탭 하나의 너비. 탭이 셋뿐이라 화면 너비에 맞추지 않고 이만큼만 넓힌다
  static let itemWidth: CGFloat = 76
  static let backgroundOpacity = 0.7
  // 화면 아래에서 띄우는 거리
  static let bottomGap: CGFloat = 6
  // 내용이 탭바에 가려지지 않게 화면 아래에 비워 둘 높이
  static let reservedHeight = height + bottomGap + 8

  // 선택한 아이콘을 채우는 그라데이션. 앱 아이콘의 파랑에서 보라로 넘어간다
  static let selectedFill = LinearGradient(
    colors: [SplashPalette.top, TechPalette.accentSoft], startPoint: .topLeading,
    endPoint: .bottomTrailing)

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
    HStack(spacing: 0) {
      ForEach(AppTab.allCases, id: \.self) { tab in
        item(tab)
          .frame(width: Self.itemWidth, height: Self.height)
      }
    }
    .padding(.horizontal, 8)
    // 뒤의 화면이 살짝 비치도록 바탕만 70%로 칠하고, 비치는 글자가 겹쳐 보이지 않게 뒤를 흐린다.
    // 아이콘·글씨·테두리는 그대로 진하게 둔다
    .background {
      ZStack {
        shape.fill(.ultraThinMaterial)
        shape.fill(
          LinearGradient(
            colors: [TechPalette.cardTop, TechPalette.cardBottom], startPoint: .topLeading,
            endPoint: .bottomTrailing)
        )
        .opacity(Self.backgroundOpacity)
      }
    }
    .overlay {
      shape.strokeBorder(
        LinearGradient(
          colors: [TechPalette.accent.opacity(0.7), TechPalette.accent.opacity(0.2)],
          startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
    }
    .shadow(color: TechPalette.accent.opacity(0.22), radius: 14)
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: selection)
  }

  private func item(_ tab: AppTab) -> some View {
    let isOn = tab == selection
    return Button {
      if isOn { onReselect(tab) } else { selection = tab }
    } label: {
      VStack(spacing: 3) {
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
    let icon = TabIcon(tab: tab).frame(width: 30, height: 28)
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

#Preview {
  @Previewable @State var selection = AppTab.interview
  VStack {
    Spacer()
    TechTabBar(selection: $selection)
  }
  .background { OnboardingBackground() }
}
