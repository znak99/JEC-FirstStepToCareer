import SwiftUI

// 총점과 거미줄 차트, 피드백, 질문 탭, 삭제 버튼 (SITE_MAP S-05, 시안 B)
struct InterviewResultView: View {
  let interviewId: String
  let onDeleted: () -> Void

  @Environment(\.apiClient) private var api
  @State private var model: InterviewResultViewModel?
  @State private var confirmingDelete = false
  @State private var selectedQuestion = 0

  var body: some View {
    Group {
      switch model?.state ?? .loading {
      case .loading:
        ResultSkeleton()
      case .evaluating:
        VStack(spacing: 16) {
          InterviewerAvatar(isActive: true)
          Text("採点しています…").font(.headline)
        }
      case .failed(let message):
        failure(message)
      case .loaded(let detail):
        content(detail)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background { TechPageBackground() }
    .reservesTabBarSpace()
    .navigationTitle("面接結果")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      if model == nil {
        let created = InterviewResultViewModel(interviewId: interviewId, api: api)
        model = created
        await created.load()
      }
    }
    .alert("この面接の記録を削除しますか？", isPresented: $confirmingDelete) {
      Button("キャンセル", role: .cancel) {}
      Button("削除", role: .destructive) {
        Task {
          if await model?.delete() == true { onDeleted() }
        }
      }
    } message: {
      Text("削除した記録は元に戻せません。")
    }
  }

  private func failure(_ message: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 40, weight: .light))
        .foregroundStyle(TechPalette.negative)
        .accessibilityHidden(true)
      Text(message)
        .font(.subheadline)
        .multilineTextAlignment(.center)
      Button("再試行") {
        Task { await model?.load() }
      }
      .buttonStyle(PrimaryButtonStyle())
      .frame(maxWidth: 240)
      .padding(.top, 4)
    }
    .padding(.horizontal, 32)
  }

  private func content(_ detail: InterviewDetail) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        ScoreSummaryCard(detail: detail)
        if let feedback = detail.feedback {
          section(1, "フィードバック") {
            Text(feedback)
              .font(.subheadline)
              .padding(18)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(TechCardBackground(showsBorder: false))
          }
        }
        if !detail.questions.isEmpty {
          section(detail.feedback == nil ? 1 : 2, "質問ごとの結果") {
            QuestionResults(questions: detail.questions, selection: $selectedQuestion)
          }
        }
        deleteButton
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .padding(.bottom, 24)
    }
  }

  private func section<Content: View>(
    _ number: Int, _ title: LocalizedStringKey, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 10) {
        Text(verbatim: String(format: "%02d", number))
          .font(.caption.monospacedDigit().weight(.bold))
          .foregroundStyle(TechPalette.accent)
        Text(title).font(.headline)
      }
      .padding(.horizontal, 4)
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.isHeader)
      content()
    }
  }

  private var deleteButton: some View {
    Button {
      confirmingDelete = true
    } label: {
      Label("この記録を削除", systemImage: "trash")
        .font(.subheadline.weight(.semibold))
        .frame(maxWidth: .infinity, minHeight: 48)
        .overlay { Capsule().strokeBorder(TechPalette.negative.opacity(0.5), lineWidth: 1) }
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .foregroundStyle(TechPalette.negative)
    .padding(.top, 4)
  }
}

// 불러오는 동안 총점 카드와 피드백 자리에 빈 상자를 둔다
private struct ResultSkeleton: View {
  var body: some View {
    ScrollView {
      DotScanSkeleton {
        VStack(alignment: .leading, spacing: 20) {
          VStack(spacing: 10) {
            SkeletonBox(width: 64, height: 14)
            SkeletonBox(width: 160, height: 52, cornerRadius: 12)
            SkeletonBox(width: 220, height: 12)
            SkeletonBox(width: 210, height: 210, cornerRadius: 105)
              .padding(.vertical, 8)
            HStack(spacing: 10) {
              SkeletonBox(height: 58, cornerRadius: 12)
              SkeletonBox(height: 58, cornerRadius: 12)
            }
          }
          .padding(18)
          .frame(maxWidth: .infinity)
          HStack(spacing: 10) {
            SkeletonBox(width: 22, height: 12)
            SkeletonBox(width: 120, height: 16)
          }
          .padding(.horizontal, 4)
          VStack(alignment: .leading, spacing: 9) {
            SkeletonBox(height: 12)
            SkeletonBox(height: 12)
            SkeletonBox(height: 12)
            SkeletonBox(width: 180, height: 12)
          }
          .padding(18)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .padding(.bottom, 24)
    }
    .scrollDisabled(true)
  }
}

// 총점, 면접 정보, 항목별 차트, 강점·약점
private struct ScoreSummaryCard: View {
  let detail: InterviewDetail

  var body: some View {
    let categories = HistoryAnalytics.categoryScores(detail.scores)
    let strengths = HistoryAnalytics.strengths(categories)
    VStack(spacing: 6) {
      Text("総合点")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
      total
      Text(verbatim: info)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      chart(categories, strengths: strengths)
      if let strengths {
        HStack(spacing: 10) {
          StrengthTile(
            title: "強み", value: strengths.strongest.label, tint: TechPalette.positive)
          StrengthTile(title: "弱み", value: strengths.weakest.label, tint: TechPalette.negative)
        }
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity)
    .background(TechCardBackground(showsBorder: false))
  }

  @ViewBuilder
  private var total: some View {
    if let value = detail.scores?.total {
      HStack(alignment: .firstTextBaseline, spacing: 2) {
        Text(verbatim: String(format: "%.1f", value))
          .font(.system(size: 52, weight: .semibold, design: .monospaced))
          .foregroundStyle(TechPalette.accent)
          .shadow(color: TechPalette.accent.opacity(0.4), radius: 8)
        Text("点").font(.title3.weight(.semibold))
      }
      .accessibilityElement(children: .combine)
    } else {
      Text("評価なし")
        .font(.title2.weight(.semibold))
        .foregroundStyle(.secondary)
    }
  }

  private var info: String {
    let date = CompletedInterview.parseDate(detail.completedAt ?? detail.startedAt)
      .map { $0.formatted(date: .abbreviated, time: .omitted) }
    return [detail.companyName, detail.jobTitle, detail.interviewType.label, date]
      .compactMap { $0 }
      .joined(separator: "・")
  }

  // 거미줄 모양은 꼭짓점이 3개 이상이어야 모양이 되므로, 시선·머리를 재지 않은 면접은 막대로 보여 준다
  @ViewBuilder
  private func chart(
    _ categories: [CategoryAverage], strengths: (strongest: ScoreMetric, weakest: ScoreMetric)?
  ) -> some View {
    if categories.count >= 3 {
      RadarChart(
        axes: categories.map {
          RadarChart.Axis(
            id: $0.metric, label: $0.metric.label, value: $0.value,
            tint: tint(for: $0.metric, strengths: strengths))
        })
    } else if !categories.isEmpty {
      TechBarChart(
        rows: categories.map {
          TechBarChart.Row(
            label: $0.metric.label, value: $0.value, caption: String(format: "%.1f", $0.value),
            tint: strengths == nil ? nil : tint(for: $0.metric, strengths: strengths))
        }
      )
      .padding(.top, 10)
    }
    if !categories.isEmpty, !categories.contains(where: { $0.metric == .gaze }) {
      Text("この面接では視線・頭の動きを測定していません")
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.bottom, 4)
    }
  }

  private func tint(
    for metric: ScoreMetric, strengths: (strongest: ScoreMetric, weakest: ScoreMetric)?
  ) -> Color {
    if metric == strengths?.strongest { return TechPalette.positive }
    if metric == strengths?.weakest { return TechPalette.negative }
    return TechPalette.accent
  }
}

// 「Q1」부터 질문 수만큼 버튼을 두고, 고른 질문의 점수·질문·답변을 보여 준다
private struct QuestionResults: View {
  let questions: [Question]
  @Binding var selection: Int

  var body: some View {
    let index = min(max(selection, 0), questions.count - 1)
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        ForEach(questions.indices, id: \.self) { item in
          QuestionTab(number: questions[item].position, isSelected: item == index) {
            selection = item
          }
        }
      }
      QuestionCard(question: questions[index])
    }
  }
}

private struct QuestionTab: View {
  let number: Int
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(verbatim: "Q\(number)")
        .font(.subheadline.weight(.bold))
        .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(TechPalette.accent))
        .frame(maxWidth: .infinity, minHeight: 38)
        .background(
          Capsule().fill(
            isSelected
              ? AnyShapeStyle(BrandPalette.fill) : AnyShapeStyle(TechPalette.cardTop))
        )
        .overlay {
          Capsule().strokeBorder(TechPalette.accent.opacity(isSelected ? 0 : 0.4), lineWidth: 1)
        }
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text("質問\(number)"))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

private struct QuestionCard: View {
  let question: Question

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      LazyVGrid(
        columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10
      ) {
        ScoreCell(title: "回答の構成", value: question.scores?.structure)
        ScoreCell(title: "回答の論理", value: question.scores?.logic)
        ScoreCell(title: "視線の動き", value: question.scores?.gaze)
        ScoreCell(title: "頭の動き", value: question.scores?.head)
      }
      VStack(alignment: .leading, spacing: 4) {
        Text("質問").font(.caption).foregroundStyle(.secondary)
        if let preface = question.preface {
          Text(preface).font(.footnote).foregroundStyle(.secondary)
        }
        Text(question.text).font(.subheadline.weight(.semibold))
      }
      VStack(alignment: .leading, spacing: 4) {
        Text("回答").font(.caption).foregroundStyle(.secondary)
        if let transcript = question.answer?.transcript {
          Text(transcript).font(.subheadline)
        } else {
          Text("（回答なし）").font(.subheadline).foregroundStyle(.secondary)
        }
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(TechCardBackground(showsBorder: false))
  }
}

private struct ScoreCell: View {
  let title: LocalizedStringKey
  let value: Double?

  var body: some View {
    HStack {
      Text(title).font(.caption).foregroundStyle(.secondary)
      Spacer(minLength: 4)
      Text(verbatim: ScoreFormat.text(value))
        .font(.subheadline.monospacedDigit().weight(.semibold))
        .foregroundStyle(value == nil ? .secondary : .primary)
    }
    .lineLimit(1)
    .padding(.horizontal, 12)
    .frame(minHeight: 38)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous).fill(TechPalette.accent.opacity(0.08))
    )
    .accessibilityElement(children: .combine)
  }
}
