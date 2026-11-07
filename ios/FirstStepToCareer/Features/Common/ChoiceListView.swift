import SwiftUI

// 업계·직종을 고르는 화면. 앱 어디서나 이 화면에서 고른다 (SITE_MAP 4절).
// 대분류를 누르면 소분류가 펼쳐지고, 고르면 바로 앞 화면으로 돌아간다.
// 「その他」를 고르면 목록을 접고 직접 입력 칸을 보여 준다
struct ChoiceListView: View {
  let title: LocalizedStringKey
  let otherPlaceholder: LocalizedStringKey
  let categories: [ChoiceCategory]
  let other: String
  // 면접 설정처럼 반드시 골라야 하면 「選択しない」를 보여 주지 않는다
  var allowsNone = true
  @Binding var choice: String
  @Binding var otherText: String

  @Environment(\.dismiss) private var dismiss
  @State private var query = ""
  @State private var expanded: Set<String> = []
  @State private var showsList = true
  @FocusState private var typing: Bool

  private var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        if showsList {
          list
            .transition(.move(edge: .top).combined(with: .opacity))
        }
        otherSection
      }
      .padding(.bottom, 24)
    }
    .scrollDismissesKeyboard(.interactively)
    .background { OnboardingBackground() }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    // 기본 뒤로 가기 버튼은 강조색을 따르지 않아 포인트 색 버튼으로 바꾼다
    .navigationBarBackButtonHidden()
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "chevron.backward")
            .foregroundStyle(TechPalette.accent)
        }
        .accessibilityLabel(Text("戻る"))
      }
    }
    // 기본 버튼을 숨기면 왼쪽 끝에서 밀어 돌아가는 동작도 꺼지므로 이 화면에서만 다시 단다
    .overlay(alignment: .leading) {
      Color.clear
        .frame(width: 20)
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 10).onEnded { value in
            if value.translation.width > 60 { dismiss() }
          })
    }
    .tint(TechPalette.accent)
    .onAppear(perform: prepare)
  }

  private func prepare() {
    if choice == other {
      showsList = false
    } else if let category = ChoiceCatalog.category(containing: choice, in: categories) {
      expanded = [category.name]
    }
  }

  // MARK: - 목록

  private var list: some View {
    let filtered = ChoiceCatalog.filter(categories, query: query)
    return VStack(alignment: .leading, spacing: 0) {
      SearchField(text: $query)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
      if allowsNone && !isSearching {
        itemRow("", indent: false) { Text("選択しない") }
        TechDivider()
      }
      ForEach(Array(filtered.enumerated()), id: \.element.id) { index, category in
        let number = (categories.firstIndex { $0.name == category.name } ?? index) + 1
        let isOpen = isSearching || expanded.contains(category.name)
        categoryHeader(category, number: number, isOpen: isOpen)
        if isOpen {
          ForEach(category.items, id: \.self) { item in
            itemRow(item, indent: true) { Text(item) }
          }
        }
        TechDivider()
      }
      if filtered.isEmpty {
        Text("見つかりませんでした。「その他」から入力できます。")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 24)
          .padding(.vertical, 20)
        TechDivider()
      }
    }
  }

  private func categoryHeader(_ category: ChoiceCategory, number: Int, isOpen: Bool) -> some View {
    Button {
      // 검색 중에는 맞는 대분류를 모두 펼쳐 둔다
      guard !isSearching else { return }
      withAnimation(.easeInOut(duration: 0.25)) {
        if expanded.contains(category.name) {
          expanded.remove(category.name)
        } else {
          expanded.insert(category.name)
        }
      }
    } label: {
      HStack(spacing: 12) {
        Text(verbatim: String(format: "%02d", number))
          .font(.caption.monospacedDigit().weight(.bold))
          .foregroundStyle(TechPalette.accent)
        Text(category.name)
          .font(.headline)
          .foregroundStyle(Color.primary)
        Spacer()
        Text(verbatim: "\(category.items.count)")
          .font(.caption.monospacedDigit())
          .foregroundStyle(Color.secondary)
        Image(systemName: "chevron.down")
          .font(.caption.weight(.semibold))
          .foregroundStyle(TechPalette.accent)
          .rotationEffect(.degrees(isOpen ? 0 : -90))
      }
      .padding(.horizontal, 24)
      .frame(minHeight: 52)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(.isHeader)
    .accessibilityValue(isOpen ? Text("開いています") : Text("閉じています"))
  }

  private func itemRow(_ value: String, indent: Bool, @ViewBuilder label: () -> some View)
    -> some View
  {
    let isOn = choice == value
    return Button {
      choice = value
      dismiss()
    } label: {
      HStack {
        label()
          .font(isOn ? .body.weight(.semibold) : .body)
          .foregroundStyle(isOn ? TechPalette.accent : Color.primary)
        Spacer()
        if isOn {
          Image(systemName: "checkmark")
            .font(.body.weight(.semibold))
            .foregroundStyle(TechPalette.accent)
        }
      }
      .padding(.leading, indent ? 44 : 24)
      .padding(.trailing, 24)
      .frame(minHeight: 46)
      .background(alignment: .leading) {
        if isOn { SelectedBar() }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isOn ? .isSelected : [])
  }

  // MARK: - その他

  private var otherSection: some View {
    let isOn = choice == other
    return VStack(alignment: .leading, spacing: 12) {
      Button {
        choice = other
        withAnimation(.easeInOut(duration: 0.3)) { showsList = false }
        typing = true
      } label: {
        HStack {
          Text(other)
            .font(isOn ? .headline : .body)
            .foregroundStyle(isOn ? TechPalette.accent : Color.primary)
          Spacer()
          if isOn {
            Image(systemName: "checkmark")
              .font(.body.weight(.semibold))
              .foregroundStyle(TechPalette.accent)
          }
        }
        .padding(.horizontal, 24)
        .frame(minHeight: 52)
        .background(alignment: .leading) {
          if isOn { SelectedBar() }
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityAddTraits(isOn ? .isSelected : [])
      if !showsList {
        VStack(alignment: .leading, spacing: 12) {
          TextField(otherPlaceholder, text: $otherText)
            .focused($typing)
            .submitLabel(.done)
            .onSubmit { dismiss() }
            .onboardingField()
          if !Profile.fits(otherText, limit: Profile.choiceLimit) {
            LimitWarning(limit: Profile.choiceLimit)
          }
          Button {
            typing = false
            withAnimation(.easeInOut(duration: 0.3)) { showsList = true }
          } label: {
            Label("リストから選ぶ", systemImage: "list.bullet")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(TechPalette.accent)
          }
          .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .transition(.opacity)
      }
    }
  }
}

// 고른 줄 왼쪽에 빛나는 세로 막대
private struct SelectedBar: View {
  var body: some View {
    Capsule()
      .fill(TechPalette.accent)
      .frame(width: 3)
      .padding(.vertical, 10)
      .shadow(color: TechPalette.accent.opacity(0.8), radius: 4)
  }
}

private struct TechDivider: View {
  var body: some View {
    Rectangle()
      .fill(TechPalette.accent.opacity(0.15))
      .frame(height: 0.5)
      .padding(.horizontal, 24)
  }
}

private struct SearchField: View {
  @Binding var text: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(TechPalette.accent)
      TextField("キーワードで検索", text: $text)
        .submitLabel(.search)
        .autocorrectionDisabled()
      if !text.isEmpty {
        Button {
          text = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(Color.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("検索をクリア"))
      }
    }
    .onboardingField()
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
      title: "業界", otherPlaceholder: "業界を入力", categories: ChoiceCatalog.industries,
      other: "その他", choice: .constant("銀行・信用金庫"), otherText: .constant(""))
  }
}
