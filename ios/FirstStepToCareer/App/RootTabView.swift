import SwiftUI

struct RootTabView: View {
  @State private var selectedTab = AppTab.interview
  // 바뀌면 모든 탭을 새로 만들어 이전 계정의 화면 상태를 지운다
  @State private var accountGeneration = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      ForEach(AppTab.allCases, id: \.self) { tab in
        Tab(tab.title, systemImage: tab.systemImage, value: tab) {
          screen(for: tab)
        }
      }
    }
    .id(accountGeneration)
  }

  @ViewBuilder
  private func screen(for tab: AppTab) -> some View {
    switch tab {
    case .interview: InterviewHomeView()
    case .history: HistoryView()
    case .menu:
      MenuView {
        selectedTab = .interview
        accountGeneration += 1
      }
    }
  }
}

#Preview {
  RootTabView()
}
