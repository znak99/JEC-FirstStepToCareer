import SwiftUI

struct InterviewSessionView: View {
  let context: InterviewSessionContext

  var body: some View {
    ContentUnavailableView("準備中", systemImage: "hammer")
      .navigationTitle("面接")
      .toolbar(.hidden, for: .tabBar)
  }
}
