import SwiftUI

// 온보딩 ①. 이용약관과 개인정보 처리방침에 동의를 받는다 (SITE_MAP S-14)
struct ConsentView: View {
  var onAgreed: () -> Void = {}

  @State private var agreed: Set<LegalDocument> = []
  @State private var reading: LegalDocument?

  private var agreedAll: Bool { agreed.count == LegalDocument.allCases.count }

  var body: some View {
    OnboardingScreen(
      step: 1, title: "ご利用の前に",
      message: "就活一歩を安心してお使いいただくため、利用規約とプライバシーポリシーをご確認ください。",
      buttonTitle: "同意して次へ", canContinue: agreedAll, onContinue: onAgreed
    ) {
      VStack(spacing: 14) {
        VStack(spacing: 16) {
          ForEach(LegalDocument.allCases) { document in
            if document != LegalDocument.allCases.first { Divider() }
            row(document)
          }
        }
        .padding(18)
        .background(TechCardBackground())
        Button {
          agreed = agreedAll ? [] : Set(LegalDocument.allCases)
        } label: {
          HStack(spacing: 12) {
            OnboardingCheck(isOn: agreedAll)
            Text("すべてに同意する").font(.headline)
            Spacer()
          }
          .padding(.horizontal, 18)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(agreedAll ? .isSelected : [])
      }
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
        HStack(spacing: 2) {
          Text("読む")
          Image(systemName: "chevron.right")
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(TechPalette.accent)
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
