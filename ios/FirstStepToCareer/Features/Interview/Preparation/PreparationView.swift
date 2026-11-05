import SwiftUI

struct PreparationView: View {
  let draft: InterviewDraft

  var body: some View {
    ContentUnavailableView("準備中", systemImage: "hammer")
      .navigationTitle("面接の準備")
  }
}
