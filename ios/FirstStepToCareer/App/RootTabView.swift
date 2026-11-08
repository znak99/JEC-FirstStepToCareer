import SwiftUI

struct RootTabView: View {
  // 로그아웃·데이터 삭제가 끝났을 때 부른다. 온보딩부터 다시 한다
  var onReset: () -> Void = {}

  @Environment(\.apiClient) private var api
  @State private var selectedTab = AppTab.interview

  var body: some View {
    TabView(selection: $selectedTab) {
      ForEach(AppTab.allCases, id: \.self) { tab in
        Tab(tab.title, systemImage: tab.systemImage, value: tab) {
          screen(for: tab)
        }
      }
    }
    // 탭 화면이 열릴 때 한 번. 평가는 오래 걸릴 수 있어 스플래시가 기다리지 않고 여기서 한다
    .task { await LeftoverInterviewCleaner(api: api).evaluatePending() }
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

#Preview {
  RootTabView()
}
