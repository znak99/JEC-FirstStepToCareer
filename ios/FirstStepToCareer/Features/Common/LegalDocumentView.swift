import SwiftUI

// 이용약관·개인정보 처리방침 본문. 온보딩 동의 화면, 시작 화면, 메뉴에서 연다 (SITE_MAP S-10·S-16)
struct LegalDocumentView: View {
  // 개인정보 문의처. 받는 설정은 Cloudflare 이메일 라우팅으로 한다 (TASK.md)
  static let supportMail = URL(string: "mailto:support@znak99.cloud")!

  let document: LegalDocument

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          Text(document.effectiveDate)
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(document.intro)
            .font(.callout)
        }
        ForEach(Array(document.sections.enumerated()), id: \.offset) { _, section in
          VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
              .font(.headline)
            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
              Text(paragraph)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
        }
        if document == .privacy {
          Link(destination: Self.supportMail) {
            Label("メールで問い合わせる", systemImage: "envelope")
              .font(.callout.weight(.semibold))
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(24)
    }
    .navigationTitle(document.title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack { LegalDocumentView(document: .privacy) }
}
