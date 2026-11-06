import SwiftUI

struct RootTabView: View {
  // 로그아웃·데이터 삭제가 끝났을 때 부른다. 시작 화면으로 돌아간다
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
    // 탭 화면이 처음 열릴 때 한 번. 백그라운드에서 돌아올 때는 실행하지 않는다
    .task { await LeftoverInterviewCleaner(api: api).run() }
  }

  @ViewBuilder
  private func screen(for tab: AppTab) -> some View {
    switch tab {
    case .interview: InterviewHomeView()
    case .history: HistoryView()
    case .menu: MenuView(onReset: onReset)
    }
  }
}

#Preview {
  RootTabView()
}
