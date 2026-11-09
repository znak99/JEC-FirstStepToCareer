import SwiftUI

// 온보딩 ①. 이용약관과 개인정보 처리방침에 동의를 받는다 (SITE_MAP S-14)
struct ConsentView: View {
  // 단계 표시. 정보 입력 없이 동의만 다시 받을 때는 nil
  var step: Int? = 1
  // 예전 버전에 동의한 적이 있으면 약관이 바뀌었다고 안내한다
  var isUpdate = false
  // 다음에 정보 입력이 없으면 동의 기록을 여기서 바로 서버에 남긴다
  var recordsOnServer = false
  var onAgreed: () -> Void = {}

  @Environment(\.apiClient) private var api
  @State private var agreed: Set<LegalDocument> = []
  @State private var reading: LegalDocument?
  @State private var isContinuing = false
  @State private var model: ProfileModel?

  var body: some View {
    OnboardingScreen(
      step: step, title: isUpdate ? "規約の更新" : "ご利用の前に",
      message: isUpdate
        ? "利用規約とプライバシーポリシーを更新しました。内容をご確認のうえ、同意をお願いします。"
        : "就活一歩を安心してお使いいただくため、利用規約とプライバシーポリシーをご確認ください。",
      // 모달에서는 다음 화면 없이 닫히므로 「次へ」를 붙이지 않는다
      buttonTitle: step == nil ? "すべてに同意する" : "すべてに同意して次へ",
      canContinue: model?.isSaving != true,
      onContinue: agreeAll
    ) {
      VStack(spacing: 12.8) {
        ForEach(LegalDocument.allCases) { document in
          if document != LegalDocument.allCases.first { Divider() }
          row(document)
        }
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 14.4)
      .background(TechCardBackground(showsBorder: false))
    }
    .loadingOverlay(model?.isSaving == true, message: "保存しています…")
    .saveFailedAlert(for: model)
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

  // 버튼은 늘 누를 수 있다. 두 항목이 체크되는 것을 보여 준 뒤 0.2초 후에 넘어간다.
  // 서버에 바로 기록해야 하면 기록에 성공했을 때만 넘어가고, 실패하면 다시 누를 수 있다
  private func agreeAll() {
    guard !isContinuing else { return }
    isContinuing = true
    withAnimation(.easeOut(duration: 0.15)) { agreed = Set(LegalDocument.allCases) }
    Task {
      try? await Task.sleep(for: .milliseconds(200))
      if recordsOnServer {
        let model = model ?? ProfileModel(api: api)
        self.model = model
        guard await model.agree(to: LegalDocument.allCases) else {
          isContinuing = false
          return
        }
      }
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
