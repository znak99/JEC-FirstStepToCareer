import SwiftUI

struct MenuView: View {
  var body: some View {
    NavigationStack {
      ContentUnavailableView("準備中", systemImage: "line.3.horizontal")
        .navigationTitle("メニュー")
    }
  }
}

#Preview {
  MenuView()
}
