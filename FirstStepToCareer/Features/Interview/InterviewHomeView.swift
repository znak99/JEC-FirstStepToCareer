import SwiftUI

struct InterviewHomeView: View {
  var body: some View {
    NavigationStack {
      ContentUnavailableView("準備中", systemImage: "person.wave.2")
        .navigationTitle("面接")
    }
  }
}

#Preview {
  InterviewHomeView()
}
