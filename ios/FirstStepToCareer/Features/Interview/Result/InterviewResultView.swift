import SwiftUI

struct InterviewResultView: View {
  let interviewId: String
  let onDeleted: () -> Void

  @Environment(\.apiClient) private var api
  @State private var model: InterviewResultModel?
  @State private var confirmingDelete = false

  var body: some View {
    Group {
      switch model?.state ?? .loading {
      case .loading:
        ProgressView()
      case .evaluating:
        VStack(spacing: 12) {
          ProgressView()
          Text("採点しています…")
        }
      case .failed(let message):
        ContentUnavailableView {
          Label(message, systemImage: "exclamationmark.triangle")
        } actions: {
          Button("再試行") { Task { await model?.load() } }
        }
      case .loaded(let detail):
        content(detail)
      }
    }
    .navigationTitle("面接結果")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      if model == nil {
        let created = InterviewResultModel(interviewId: interviewId, api: api)
        model = created
        await created.load()
      }
    }
    .confirmationDialog(
      "この面接の記録を削除しますか？", isPresented: $confirmingDelete, titleVisibility: .visible
    ) {
      Button("削除", role: .destructive) {
        Task {
          if await model?.delete() == true { onDeleted() }
        }
      }
    }
  }

  private func content(_ detail: InterviewDetail) -> some View {
    List {
      Section {
        VStack(spacing: 4) {
          Text("総合点").font(.subheadline).foregroundStyle(.secondary)
          Text(ScoreFormat.text(detail.scores?.total))
            .font(.system(size: 44, weight: .bold))
          Text("\(detail.companyName)・\(detail.jobTitle)・\(detail.interviewType.label)")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
      }
      Section("項目別") {
        ScoreRows(
          structure: detail.scores?.structure, logic: detail.scores?.logic,
          gaze: detail.scores?.gaze, head: detail.scores?.head)
      }
      if let feedback = detail.feedback {
        Section("フィードバック") { Text(feedback) }
      }
      ForEach(detail.questions) { question in
        Section("質問\(question.position)") {
          ScoreRows(
            structure: question.scores?.structure, logic: question.scores?.logic,
            gaze: question.scores?.gaze, head: question.scores?.head)
          VStack(alignment: .leading, spacing: 4) {
            Text("質問").font(.caption).foregroundStyle(.secondary)
            Text(question.text)
          }
          VStack(alignment: .leading, spacing: 4) {
            Text("回答").font(.caption).foregroundStyle(.secondary)
            Text(question.answer?.transcript ?? "（回答なし）")
          }
        }
      }
      Section {
        Button("この記録を削除", role: .destructive) { confirmingDelete = true }
      }
    }
  }
}

private struct ScoreRows: View {
  let structure: Double?
  let logic: Double?
  let gaze: Double?
  let head: Double?

  var body: some View {
    LabeledContent("回答の構成", value: ScoreFormat.text(structure))
    LabeledContent("回答の論理", value: ScoreFormat.text(logic))
    LabeledContent("視線の動き", value: ScoreFormat.text(gaze))
    LabeledContent("頭の動き", value: ScoreFormat.text(head))
  }
}
