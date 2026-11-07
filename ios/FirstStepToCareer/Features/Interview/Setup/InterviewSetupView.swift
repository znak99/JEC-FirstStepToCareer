import SwiftUI

struct InterviewSetupView: View {
  let onNext: (InterviewDraft) -> Void

  @State private var draft: InterviewDraft
  @State private var industryChoice: String
  @State private var otherIndustry: String
  @State private var jobChoice: String
  @State private var otherJob: String

  private static let other = ProfileDraft.other

  // 프로필의 희망 조건을 미리 채운다. 이 화면에서 바꾼 값은 프로필에 저장하지 않는다
  init(profile: Profile? = ProfileStore().profile, onNext: @escaping (InterviewDraft) -> Void) {
    self.onNext = onNext
    var draft = InterviewDraft(questionCount: AppSettings.questionCount())
    draft.hiringType = profile?.hiringType ?? .newGrad
    let filled = profile.map(ProfileDraft.init) ?? ProfileDraft()
    _draft = State(initialValue: draft)
    _industryChoice = State(initialValue: filled.industryChoice)
    _otherIndustry = State(initialValue: filled.otherIndustry)
    _jobChoice = State(initialValue: filled.jobChoice)
    _otherJob = State(initialValue: filled.otherJob)
  }

  var body: some View {
    Form {
      Section("会社名") {
        TextField("例：就活一歩株式会社", text: $draft.companyName)
          .textInputAutocapitalization(.never)
          .submitLabel(.done)
      }
      // 업계·직종은 앱 어디서나 새 화면에서 고른다 (SITE_MAP 4절)
      Section("業界") {
        NavigationLink {
          ChoiceListView(
            title: "業界", otherPlaceholder: "業界を入力", categories: ChoiceCatalog.industries,
            other: Self.other, allowsNone: false, choice: $industryChoice,
            otherText: $otherIndustry)
        } label: {
          ChoiceValue(choice: industryChoice, otherText: otherIndustry, other: Self.other)
        }
      }
      Section("職種") {
        NavigationLink {
          ChoiceListView(
            title: "職種", otherPlaceholder: "職種を入力", categories: ChoiceCatalog.jobTitles,
            other: Self.other, allowsNone: false, choice: $jobChoice, otherText: $otherJob)
        } label: {
          ChoiceValue(choice: jobChoice, otherText: otherJob, other: Self.other)
        }
      }
      Section("面接の種類") {
        Picker("面接の種類", selection: $draft.interviewType) {
          ForEach(InterviewType.allCases, id: \.self) { Text($0.label).tag($0) }
        }
        .pickerStyle(.segmented)
      }
      Section("採用区分") {
        Picker("採用区分", selection: $draft.hiringType) {
          ForEach(HiringType.allCases, id: \.self) { Text($0.label).tag($0) }
        }
        .pickerStyle(.segmented)
      }
      Section {
        LabeledContent("質問数", value: "\(draft.questionCount)問")
      } footer: {
        Text("質問数はメニューで変更できます。")
      }
    }
    .scrollDismissesKeyboard(.immediately)
    .navigationTitle("面接の設定")
    .navigationBarTitleDisplayMode(.inline)
    .safeAreaInset(edge: .bottom) {
      Button {
        onNext(resolvedDraft)
      } label: {
        Text("次へ").frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(!resolvedDraft.isValid)
      .padding()
      .background(.bar)
    }
  }

  private var resolvedDraft: InterviewDraft {
    var value = draft
    value.industry = industryChoice == Self.other ? otherIndustry : industryChoice
    value.jobTitle = jobChoice == Self.other ? otherJob : jobChoice
    return value
  }
}

// 고른 값을 보여 준다. 「その他」면 직접 입력한 값을 보여 준다
private struct ChoiceValue: View {
  let choice: String
  let otherText: String
  let other: String

  var body: some View {
    if choice.isEmpty {
      Text("選択してください").foregroundStyle(.secondary)
    } else if choice == other, let typed = Profile.trimmed(otherText) {
      Text(typed)
    } else {
      Text(choice)
    }
  }
}

#Preview {
  NavigationStack { InterviewSetupView { _ in } }
}
