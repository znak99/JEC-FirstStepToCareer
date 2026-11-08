import SwiftUI

// 이용약관·프라이버시 폴리시. 머리말 카드, 목차, 본문 (SITE_MAP S-10/S-16, 시안 B).
// 메뉴에서 열 때와 시작·동의 화면에서 아래 창으로 열 때 모두 쓴다
struct LegalDocumentView: View {
  // 개인정보 문의처. 받는 설정은 Cloudflare 이메일 라우팅으로 한다 (TASK.md)
  static let supportMail = URL(string: "mailto:support@znak99.cloud")!

  let document: LegalDocument

  var body: some View {
    let sections = Array(document.sections.enumerated())
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          header
          contents(sections) { index in
            withAnimation { proxy.scrollTo(index, anchor: .top) }
          }
          ForEach(sections, id: \.offset) { index, section in
            VStack(alignment: .leading, spacing: 8) {
              HStack(spacing: 8) {
                Capsule()
                  .fill(TechPalette.accent)
                  .frame(width: 3, height: 16)
                  .shadow(color: TechPalette.accent.opacity(0.8), radius: 3)
                  .accessibilityHidden(true)
                Text(section.title)
                  .font(.headline)
                  .accessibilityAddTraits(.isHeader)
              }
              ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                  .font(.callout)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
            .padding(.horizontal, 4)
            .id(index)
          }
          if document == .privacy {
            Link(destination: Self.supportMail) {
              Label("メールで問い合わせる", systemImage: "envelope.fill")
            }
            .buttonStyle(OnboardingButtonStyle())
            .padding(.top, 4)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
      }
    }
    .background { OnboardingBackground() }
    .navigationTitle(document.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(document.effectiveDate)
        .font(.caption.weight(.semibold))
        .foregroundStyle(TechPalette.accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(TechPalette.accent.opacity(0.1)))
      Text(document.intro).font(.callout)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(TechCardBackground())
  }

  // 줄을 누르면 그 조항까지 내려간다
  private func contents(
    _ sections: [(offset: Int, element: LegalSection)], onSelect: @escaping (Int) -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("目次")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
        .accessibilityAddTraits(.isHeader)
      ForEach(sections, id: \.offset) { index, section in
        Button {
          onSelect(index)
        } label: {
          HStack(spacing: 10) {
            Text(section.title)
              .font(.subheadline)
              .foregroundStyle(.primary)
              .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Image(systemName: "arrow.down.right")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(TechPalette.accent)
              .accessibilityHidden(true)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 9)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.bottom, 8)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(TechCardBackground(showsBorder: false))
  }
}

#Preview {
  NavigationStack { LegalDocumentView(document: .privacy) }
}
