import SwiftUI

struct RootTabView: View {
  @State private var selectedTab = AppTab.interview

  var body: some View {
    TabView(selection: $selectedTab) {
      ForEach(AppTab.allCases, id: \.self) { tab in
        Tab(tab.title, systemImage: tab.systemImage, value: tab) {
          screen(for: tab)
        }
      }
    }
  }

  @ViewBuilder
  private func screen(for tab: AppTab) -> some View {
    switch tab {
    case .interview: InterviewHomeView()
    case .history: HistoryView()
    case .menu: MenuView()
    }
  }
}

#Preview {
  RootTabView()
}
