import SwiftUI

struct InterviewSetupView: View {
  let onNext: (InterviewDraft) -> Void

  @State private var draft = InterviewDraft(questionCount: AppSettings.questionCount())
  @State private var industryChoice = ""
  @State private var otherIndustry = ""
  @State private var jobChoice = ""
  @State private var otherJob = ""

  private static let other = "その他"

  var body: some View {
    Form {
      Section("会社名") {
        TextField("例：就活一歩株式会社", text: $draft.companyName)
          .textInputAutocapitalization(.never)
          .submitLabel(.done)
      }
      Section("業界") {
        ChoicePicker(
          title: "業界", options: InterviewDraft.industries + [Self.other],
          selection: $industryChoice)
        if industryChoice == Self.other {
          TextField("業界を入力", text: $otherIndustry)
        }
      }
      Section("職種") {
        ChoicePicker(
          title: "職種", options: InterviewDraft.jobTitles + [Self.other],
          selection: $jobChoice)
        if jobChoice == Self.other {
          TextField("職種を入力", text: $otherJob)
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

private struct ChoicePicker: View {
  let title: String
  let options: [String]
  @Binding var selection: String

  var body: some View {
    Picker(title, selection: $selection) {
      Text("選択してください").tag("")
      ForEach(options, id: \.self) { Text($0).tag($0) }
    }
  }
}

#Preview {
  NavigationStack { InterviewSetupView { _ in } }
}
