import SwiftUI

// 업계·직종을 고르는 목록 화면. 고르면 바로 앞 화면으로 돌아간다.
// 「その他」를 고르면 이 화면에 직접 입력 칸을 보여 준다
struct ChoiceListView: View {
  let title: LocalizedStringKey
  let otherPlaceholder: LocalizedStringKey
  let options: [String]
  let other: String
  @Binding var choice: String
  @Binding var otherText: String

  @Environment(\.dismiss) private var dismiss
  @FocusState private var typing: Bool

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        VStack(spacing: 0) {
          row(value: "") { Text("選択しない") }
          ForEach(options + [other], id: \.self) { option in
            Divider().padding(.leading, 18)
            row(value: option) { Text(option) }
          }
        }
        .background(TechCardBackground())
        if choice == other {
          TextField(otherPlaceholder, text: $otherText)
            .focused($typing)
            .submitLabel(.done)
            .onSubmit { dismiss() }
            .onboardingField()
          if !Profile.fits(otherText, limit: Profile.choiceLimit) {
            LimitWarning(limit: Profile.choiceLimit)
          }
        }
      }
      .padding(24)
    }
    .scrollDismissesKeyboard(.interactively)
    .background { OnboardingBackground() }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private func row(value: String, @ViewBuilder label: () -> some View) -> some View {
    let isOn = choice == value
    return Button {
      choice = value
      if value == other {
        typing = true
      } else {
        dismiss()
      }
    } label: {
      HStack {
        label()
        Spacer()
        if isOn {
          Image(systemName: "checkmark")
            .font(.body.weight(.semibold))
            .foregroundStyle(TechPalette.accent)
        }
      }
      .padding(.horizontal, 18)
      .frame(minHeight: 48)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isOn ? .isSelected : [])
  }
}

#Preview {
  NavigationStack {
    ChoiceListView(
      title: "業界", otherPlaceholder: "業界を入力", options: InterviewDraft.industries,
      other: "その他", choice: .constant("IT"), otherText: .constant(""))
  }
}
