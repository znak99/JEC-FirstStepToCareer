import SwiftUI

// 온보딩 ①. 이용약관과 개인정보 처리방침에 동의를 받는다 (SITE_MAP S-14)
struct ConsentView: View {
  var onAgreed: () -> Void = {}

  @State private var agreed: Set<LegalDocument> = []
  @State private var reading: LegalDocument?
  @State private var isContinuing = false

  var body: some View {
    OnboardingScreen(
      step: 1, title: "ご利用の前に",
      message: "就活一歩を安心してお使いいただくため、利用規約とプライバシーポリシーをご確認ください。",
      buttonTitle: "すべてに同意して次へ", canContinue: true, onContinue: agreeAll
    ) {
      VStack(spacing: 12.8) {
        ForEach(LegalDocument.allCases) { document in
          if document != LegalDocument.allCases.first { Divider() }
          row(document)
        }
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 14.4)
      .background(TechCardBackground())
    }
    .sheet(item: $reading) { document in
      NavigationStack {
        LegalDocumentView(document: document)
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("閉じる") { reading = nil }
            }
          }
      }
    }
  }

  // 버튼은 늘 누를 수 있다. 두 항목이 체크되는 것을 보여 준 뒤 0.2초 후에 넘어간다
  private func agreeAll() {
    guard !isContinuing else { return }
    isContinuing = true
    withAnimation(.easeOut(duration: 0.15)) { agreed = Set(LegalDocument.allCases) }
    Task {
      try? await Task.sleep(for: .milliseconds(200))
      onAgreed()
    }
  }

  private func row(_ document: LegalDocument) -> some View {
    let isOn = agreed.contains(document)
    return HStack(spacing: 12) {
      Button {
        if isOn { agreed.remove(document) } else { agreed.insert(document) }
      } label: {
        HStack(spacing: 12) {
          OnboardingCheck(isOn: isOn)
          VStack(alignment: .leading, spacing: 2) {
            Text(document.title).font(.headline)
            Text(document.summary).font(.caption).foregroundStyle(.secondary)
          }
          Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityAddTraits(isOn ? .isSelected : [])
      Button {
        reading = document
      } label: {
        Image(systemName: "chevron.right")
          .font(.subheadline)
          .foregroundStyle(TechPalette.accent)
          // 글자를 없애 작아진 누를 곳을 넓힌다. 높이는 줄 높이를 넘지 않게 한다
          .frame(minWidth: 44, minHeight: 36, alignment: .trailing)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(Text("\(Text(document.title))を読む"))
    }
  }
}

extension LegalDocument {
  var title: LocalizedStringKey {
    switch self {
    case .terms: "利用規約"
    case .privacy: "プライバシーポリシー"
    }
  }

  var summary: LocalizedStringKey {
    switch self {
    case .terms: "サービスの使い方とお約束"
    case .privacy: "データの扱いと保存先"
    }
  }
}

#Preview {
  ConsentView()
}
