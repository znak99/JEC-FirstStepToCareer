import Observation
import SwiftUI

// 하단 탭바(App/TechTabBar)를 숨겨 달라는 화면을 모은다 (SITE_MAP 4절).
// 화면이 넘어가는 동안 두 화면이 함께 요청할 수 있어, 화면마다 따로 기억한다
@MainActor
@Observable
final class TabBarVisibility {
  private var hidingScreens: Set<UUID> = []

  var isHidden: Bool { !hidingScreens.isEmpty }

  func hide(for screen: UUID) {
    hidingScreens.insert(screen)
  }

  func show(for screen: UUID) {
    hidingScreens.remove(screen)
  }
}

extension EnvironmentValues {
  @Entry var tabBarVisibility: TabBarVisibility?
  // 하단 탭바가 보일 때 화면 아래에 비워 둘 높이. 탭 밖(온보딩 등)에서는 0
  @Entry var tabBarInset: CGFloat = 0
}

extension View {
  // 이 화면이 보이는 동안 하단 탭바를 숨긴다(면접 준비·면접 진행)
  func hidesTabBar() -> some View {
    modifier(HidesTabBar())
  }
}

extension View {
  // 하단 탭바에 내용이 가려지지 않게 화면 아래를 비워 둔다. 탭 안의 화면마다 맨 바깥에 붙인다
  func reservesTabBarSpace() -> some View {
    modifier(ReservesTabBarSpace())
  }
}

private struct ReservesTabBarSpace: ViewModifier {
  @Environment(\.tabBarInset) private var inset

  func body(content: Content) -> some View {
    content.safeAreaInset(edge: .bottom, spacing: 0) {
      Color.clear.frame(height: inset).allowsHitTesting(false)
    }
  }
}

private struct HidesTabBar: ViewModifier {
  @Environment(\.tabBarVisibility) private var visibility
  @State private var screen = UUID()

  func body(content: Content) -> some View {
    content
      .onAppear { visibility?.hide(for: screen) }
      .onDisappear { visibility?.show(for: screen) }
  }
}
