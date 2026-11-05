import SwiftUI

struct HistoryView: View {
  var body: some View {
    NavigationStack {
      ContentUnavailableView("準備中", systemImage: "chart.xyaxis.line")
        .navigationTitle("記録")
    }
  }
}

#Preview {
  HistoryView()
}
