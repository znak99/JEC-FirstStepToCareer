import SwiftUI

// 온보딩 ②. 이름(닉네임, 필수)과 희망 조건(선택)을 받는다 (SITE_MAP S-15)
struct ProfileSetupView: View {
  var onFinished: (Profile) -> Void = { _ in }

  @State private var nickname = ""
  @State private var hiringType: HiringType?
  @State private var industryChoice = ""
  @State private var otherIndustry = ""
  @State private var jobChoice = ""
  @State private var otherJob = ""

  static let other = "その他"

  private enum Choice: Hashable {
    case industry, jobTitle
  }

  private var profile: Profile? {
    Profile(
      nickname: nickname, hiringType: hiringType,
      industry: industryChoice == Self.other ? otherIndustry : industryChoice,
      jobTitle: jobChoice == Self.other ? otherJob : jobChoice)
  }

  var body: some View {
    NavigationStack {
      OnboardingScreen(
        step: 2, title: "あなたについて\n教えてください",
        message: "お名前（ニックネーム）だけで始められます。\nほかの項目は後からメニューで変更できます。",
        buttonTitle: "はじめる", canContinue: profile != nil
      ) {
        if let profile { onFinished(profile) }
      } content: {
        form
      }
      .toolbar(.hidden, for: .navigationBar)
      // 업계·직종은 앱 어디서나 새 화면에서 고른다 (SITE_MAP 4절)
      .navigationDestination(for: Choice.self) { choice in
        switch choice {
        case .industry:
          ChoiceListView(
            title: "業界", otherPlaceholder: "業界を入力", options: InterviewDraft.industries,
            other: Self.other, choice: $industryChoice, otherText: $otherIndustry)
        case .jobTitle:
          ChoiceListView(
            title: "職種", otherPlaceholder: "職種を入力", options: InterviewDraft.jobTitles,
            other: Self.other, choice: $jobChoice, otherText: $otherJob)
        }
      }
    }
  }

  private var form: some View {
    VStack(alignment: .leading, spacing: 18) {
      VStack(alignment: .leading, spacing: 8) {
        OnboardingFieldLabel(title: "お名前（ニックネーム）", isRequired: true)
        TextField("例：たろう", text: $nickname)
          .textContentType(.nickname)
          .submitLabel(.done)
          .onboardingField()
        if Profile.fits(nickname, limit: Profile.nicknameLimit) {
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
      choiceRow("業界", value: Choice.industry, choice: industryChoice, otherText: otherIndustry)
      choiceRow("職種", value: Choice.jobTitle, choice: jobChoice, otherText: otherJob)
    }
    .padding(18)
    .background(TechCardBackground())
  }

  // 다시 누르면 선택을 지운다. 고르지 않아도 된다
  private func hiringButton(_ type: HiringType) -> some View {
    let isOn = hiringType == type
    return Button {
      hiringType = isOn ? nil : type
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
    _ title: LocalizedStringKey, value: Choice, choice: String, otherText: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      OnboardingFieldLabel(title: title, isRequired: false)
      NavigationLink(value: value) {
        HStack {
          if choice.isEmpty {
            Text("選択しない").foregroundStyle(Color.secondary)
          } else if choice == Self.other, let typed = Profile.trimmed(otherText) {
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
      if choice == Self.other, !Profile.fits(otherText, limit: Profile.choiceLimit) {
        LimitWarning(limit: Profile.choiceLimit)
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

#Preview {
  ProfileSetupView()
}
