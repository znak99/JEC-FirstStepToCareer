import SwiftUI

// 이름(닉네임)과 희망 조건을 입력하는 카드. 온보딩 정보 입력(S-15)과 메뉴의 프로필(S-17)이 함께 쓴다.
// 업계·직종 줄은 새 화면으로 넘어가므로 쓰는 쪽에서 profileChoiceDestinations를 붙인다
struct ProfileFormCard: View {
  @Binding var draft: ProfileDraft

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      VStack(alignment: .leading, spacing: 8) {
        OnboardingFieldLabel(title: "お名前（ニックネーム）", isRequired: true)
        TextField("例：たろう", text: $draft.nickname)
          .textContentType(.nickname)
          .submitLabel(.done)
          .onboardingField()
        if Profile.fits(draft.nickname, limit: Profile.nicknameLimit) {
          Text("面接官があなたを呼ぶときに使います")
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
          LimitWarning(limit: Profile.nicknameLimit)
        }
      }
      VStack(alignment: .leading, spacing: 8) {
        OnboardingFieldLabel(title: "採用区分", isRequired: false)
        HStack(spacing: 10) {
          ForEach(HiringType.allCases, id: \.self) { type in
            hiringButton(type)
          }
        }
      }
      choiceRow(
        "業界", value: ProfileChoice.industry, choice: draft.industryChoice,
        otherText: draft.otherIndustry)
      choiceRow(
        "職種", value: ProfileChoice.jobTitle, choice: draft.jobChoice, otherText: draft.otherJob)
    }
    .padding(18)
    .background(TechCardBackground())
  }

  // 다시 누르면 선택을 지운다. 고르지 않아도 된다
  private func hiringButton(_ type: HiringType) -> some View {
    let isOn = draft.hiringType == type
    return Button {
      draft.hiringType = isOn ? nil : type
    } label: {
      Label {
        Text(type.label)
      } icon: {
        // 글자보다 작고 가는 선으로 그린다
        Image(systemName: type.symbolName)
          .font(.footnote.weight(.light))
      }
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(isOn ? TechPalette.cardBottom : .primary)
      .frame(maxWidth: .infinity, minHeight: 40)
      .background(Capsule().fill(isOn ? TechPalette.accent : TechPalette.cardTop))
      .overlay { Capsule().strokeBorder(TechPalette.accent.opacity(0.3), lineWidth: 1) }
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isOn ? .isSelected : [])
  }

  // 누르면 목록 화면으로 넘어간다. 「その他」면 직접 입력한 값을 보여 준다
  private func choiceRow(
    _ title: LocalizedStringKey, value: ProfileChoice, choice: String, otherText: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      OnboardingFieldLabel(title: title, isRequired: false)
      NavigationLink(value: value) {
        HStack {
          if choice.isEmpty {
            Text("選択しない").foregroundStyle(Color.secondary)
          } else if choice == ProfileDraft.other, let typed = Profile.trimmed(otherText) {
            Text(typed)
          } else {
            Text(choice)
          }
          Spacer()
          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(Color.secondary)
        }
        .onboardingField()
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(Text(title))
      if choice == ProfileDraft.other, !Profile.fits(otherText, limit: Profile.choiceLimit) {
        LimitWarning(limit: Profile.choiceLimit)
      }
    }
  }
}

enum ProfileChoice: Hashable {
  case industry, jobTitle
}

extension View {
  // 업계·직종은 앱 어디서나 새 화면에서 고른다 (SITE_MAP 4절)
  func profileChoiceDestinations(_ draft: Binding<ProfileDraft>) -> some View {
    navigationDestination(for: ProfileChoice.self) { choice in
      switch choice {
      case .industry:
        ChoiceListView(
          title: "業界", otherPlaceholder: "業界を入力", categories: ChoiceCatalog.industries,
          other: ProfileDraft.other, choice: draft.industryChoice, otherText: draft.otherIndustry)
      case .jobTitle:
        ChoiceListView(
          title: "職種", otherPlaceholder: "職種を入力", categories: ChoiceCatalog.jobTitles,
          other: ProfileDraft.other, choice: draft.jobChoice, otherText: draft.otherJob)
      }
    }
  }
}

extension HiringType {
  // 新卒는 학사모, 中途는 서류 가방
  var symbolName: String {
    switch self {
    case .newGrad: "graduationcap"
    case .midCareer: "briefcase"
    }
  }
}
