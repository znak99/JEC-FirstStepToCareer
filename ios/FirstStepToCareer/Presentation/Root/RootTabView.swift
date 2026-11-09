import SwiftUI

struct RootTabView: View {
  // 로그아웃·데이터 삭제가 끝났을 때 부른다. 온보딩부터 다시 한다
  var onReset: () -> Void = {}

  @Environment(\.useCases) private var useCases
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var selectedTab = AppTab.interview
  @State private var tabBarVisibility = TabBarVisibility()
  @State private var isKeyboardVisible = false
  @State private var rootRequests: [AppTab: Int] = [:]

  var body: some View {
    // 키보드가 올라오면 탭바는 키보드 뒤로 빠지고, 화면의 아래 버튼이 키보드 바로 위에 붙는다
    let showsTabBar = !tabBarVisibility.isHidden && !isKeyboardVisible
    TabView(selection: $selectedTab) {
      ForEach(AppTab.allCases, id: \.self) { tab in
        Tab(tab.title, systemImage: tab.systemImage, value: tab) {
          screen(for: tab)
            // iOS 기본 탭바 대신 아래의 TechTabBar를 쓴다
            .toolbar(.hidden, for: .tabBar)
            .environment(\.tabRootRequest, rootRequests[tab, default: 0])
        }
      }
    }
    .overlay(alignment: .bottom) {
      if showsTabBar {
        TechTabBar(selection: $selectedTab) { rootRequests[$0, default: 0] += 1 }
          .padding(.bottom, TechTabBar.bottomGap)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: showsTabBar)
    .environment(\.tabBarVisibility, tabBarVisibility)
    // 탭과 내비게이션 바깥에서 준 여백은 안쪽 화면에 닿지 않아, 화면마다 reservesTabBarSpace로 비운다
    .environment(\.tabBarInset, showsTabBar ? TechTabBar.reservedHeight : 0)
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification))
    { _ in
      isKeyboardVisible = true
    }
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
    { _ in
      isKeyboardVisible = false
    }
    // 탭 화면이 열릴 때 한 번. 평가는 오래 걸릴 수 있어 스플래시가 기다리지 않고 여기서 한다
    .task { await useCases.evaluatePendingInterviews.execute() }
  }

  @ViewBuilder
  private func screen(for tab: AppTab) -> some View {
    switch tab {
    case .interview: InterviewHomeView()
    case .history: HistoryView { selectedTab = .interview }
    case .menu: MenuView(onReset: onReset)
    }
  }
}
