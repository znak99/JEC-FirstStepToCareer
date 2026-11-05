import SwiftUI

struct AnalyticsView: View {
  var body: some View {
    NavigationStack {
      ContentUnavailableView("準備中", systemImage: "chart.xyaxis.line")
        .navigationTitle("分析")
    }
  }
}

#Preview {
  AnalyticsView()
}
