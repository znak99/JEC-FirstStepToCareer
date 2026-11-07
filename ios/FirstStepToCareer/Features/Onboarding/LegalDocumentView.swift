import SwiftUI

// 이용약관·개인정보 처리방침 본문
struct LegalDocumentView: View {
  let document: LegalDocument

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        // 본문은 다음 단계에서 넣는다 (TASK.md 온보딩 구현)
        Text("本文は準備中です。")
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(24)
    }
    .navigationTitle(document.title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack { LegalDocumentView(document: .terms) }
}
