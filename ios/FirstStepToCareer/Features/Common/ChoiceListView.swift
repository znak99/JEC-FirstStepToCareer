import SwiftUI

// 업계·직종을 고르는 목록 화면. 앱 어디서나 이 화면에서 고른다 (SITE_MAP 4절).
// 고르면 바로 앞 화면으로 돌아가고, 「その他」를 고르면 이 화면에 직접 입력 칸을 보여 준다
struct ChoiceListView: View {
  let title: LocalizedStringKey
  let otherPlaceholder: LocalizedStringKey
  let options: [String]
  let other: String
  // 면접 설정처럼 반드시 골라야 하면 「選択しない」를 보여 주지 않는다
  var allowsNone = true
  @Binding var choice: String
  @Binding var otherText: String

  @Environment(\.dismiss) private var dismiss
  @FocusState private var typing: Bool

  var body: some View {
    List {
      if allowsNone {
        row(value: "") { Text("選択しない") }
      }
      ForEach(options + [other], id: \.self) { option in
        row(value: option) { Text(option) }
      }
      if choice == other {
        TextField(otherPlaceholder, text: $otherText)
          .focused($typing)
          .submitLabel(.done)
          .onSubmit { dismiss() }
        if !Profile.fits(otherText, limit: Profile.choiceLimit) {
          LimitWarning(limit: Profile.choiceLimit)
        }
      }
    }
    .listStyle(.plain)
    .scrollDismissesKeyboard(.interactively)
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
        label().foregroundStyle(Color.primary)
        Spacer()
        if isOn {
          Image(systemName: "checkmark")
            .font(.body.weight(.semibold))
            .foregroundStyle(TechPalette.accent)
        }
      }
      .contentShape(Rectangle())
    }
    .accessibilityAddTraits(isOn ? .isSelected : [])
  }
}

struct LimitWarning: View {
  let limit: Int

  var body: some View {
    Text("\(limit)文字以内で入力してください")
      .font(.caption)
      .foregroundStyle(TechPalette.negative)
  }
}

#Preview {
  NavigationStack {
    ChoiceListView(
      title: "業界", otherPlaceholder: "業界を入力", options: InterviewDraft.industries,
      other: "その他", choice: .constant("IT"), otherText: .constant(""))
  }
}
