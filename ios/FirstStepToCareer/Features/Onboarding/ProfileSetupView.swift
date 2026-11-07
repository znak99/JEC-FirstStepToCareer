import SwiftUI

// 온보딩 ②. 닉네임(필수)과 희망 조건(선택)을 받는다 (SITE_MAP S-15)
struct ProfileSetupView: View {
  var onFinished: (Profile) -> Void = { _ in }

  @State private var nickname = ""
  @State private var hiringType: HiringType?
  @State private var industryChoice = ""
  @State private var otherIndustry = ""
  @State private var jobChoice = ""
  @State private var otherJob = ""

  static let other = "その他"

  private var profile: Profile? {
    Profile(
      nickname: nickname, hiringType: hiringType,
      industry: industryChoice == Self.other ? otherIndustry : industryChoice,
      jobTitle: jobChoice == Self.other ? otherJob : jobChoice)
  }

  var body: some View {
    OnboardingScreen(
      step: 2, title: "あなたについて\n教えてください",
      message: "ニックネームだけで始められます。ほかの項目はあとからメニューで変更できます。",
      buttonTitle: "はじめる", canContinue: profile != nil
    ) {
      if let profile { onFinished(profile) }
    } content: {
      VStack(alignment: .leading, spacing: 18) {
        VStack(alignment: .leading, spacing: 8) {
          OnboardingFieldLabel(title: "ニックネーム", isRequired: true)
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
        ChoiceField(
          title: "希望業界", otherPlaceholder: "業界を入力",
          options: InterviewDraft.industries, choice: $industryChoice, other: $otherIndustry)
        ChoiceField(
          title: "希望職種", otherPlaceholder: "職種を入力",
          options: InterviewDraft.jobTitles, choice: $jobChoice, other: $otherJob)
      }
      .padding(18)
      .background(TechCardBackground())
    }
  }

  // 다시 누르면 선택을 지운다. 고르지 않아도 된다
  private func hiringButton(_ type: HiringType) -> some View {
    let isOn = hiringType == type
    return Button {
      hiringType = isOn ? nil : type
    } label: {
      Text(type.label)
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
}

// 목록에서 고르고, 「その他」면 직접 입력한다. 면접 설정 화면과 같은 목록이다
private struct ChoiceField: View {
  let title: LocalizedStringKey
  let otherPlaceholder: LocalizedStringKey
  let options: [String]
  @Binding var choice: String
  @Binding var other: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      OnboardingFieldLabel(title: title, isRequired: false)
      Menu {
        Button("選択しない") { choice = "" }
        ForEach(options + [ProfileSetupView.other], id: \.self) { option in
          Button(option) { choice = option }
        }
      } label: {
        // 메뉴 안의 글자는 강조색으로 물들므로 회색·기본색을 직접 정한다
        HStack {
          if choice.isEmpty {
            Text("選択しない").foregroundStyle(Color.secondary)
          } else {
            Text(choice).foregroundStyle(Color.primary)
          }
          Spacer()
          Image(systemName: "chevron.up.chevron.down")
            .font(.caption)
            .foregroundStyle(Color.secondary)
        }
        .onboardingField()
      }
      .accessibilityLabel(Text(title))
      if choice == ProfileSetupView.other {
        TextField(otherPlaceholder, text: $other)
          .submitLabel(.done)
          .onboardingField()
        if !Profile.fits(other, limit: Profile.choiceLimit) {
          LimitWarning(limit: Profile.choiceLimit)
        }
      }
    }
  }
}

private struct LimitWarning: View {
  let limit: Int

  var body: some View {
    Text("\(limit)文字以内で入力してください")
      .font(.caption)
      .foregroundStyle(TechPalette.negative)
  }
}

#Preview {
  ProfileSetupView()
}
