import SwiftUI

enum HistoryRoute: Hashable {
  case analysis
  case result(String)
}

// 요약 카드와 달별 면접 목록 (SITE_MAP S-08, 시안 A)
struct HistoryView: View {
  // 기록이 없을 때 「面接を始める」를 누르면 면접 탭으로 옮긴다
  var onStartInterview: () -> Void = {}

  @Environment(\.apiClient) private var api
  @State private var model: HistoryModel?
  @State private var path: [HistoryRoute] = []

  var body: some View {
    NavigationStack(path: $path) {
      Group {
        // 화면 상태를 만드는 한순간에는 바탕만 보여 준다
        if let model {
          content(model)
        } else {
          Color.clear
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background { OnboardingBackground() }
      .navigationTitle("記録")
      .navigationDestination(for: HistoryRoute.self) { route in
        switch route {
        case .analysis:
          AnalysisView(interviews: model?.interviews ?? [])
        case .result(let id):
          InterviewResultView(interviewId: id) { path.removeLast() }
        }
      }
      // 탭을 열 때와 결과 화면에서 돌아올 때마다 다시 불러온다
      .task {
        let current = model ?? HistoryModel(api: api)
        model = current
        await current.load()
      }
    }
  }

  @ViewBuilder
  private func content(_ model: HistoryModel) -> some View {
    if !model.hasLoaded {
      if model.loadFailed {
        failure(model)
      } else {
        HistorySkeleton()
      }
    } else if model.interviews.isEmpty {
      empty(model)
    } else {
      list(model)
    }
  }

  private func failure(_ model: HistoryModel) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "wifi.exclamationmark")
        .font(.system(size: 40, weight: .light))
        .foregroundStyle(TechPalette.negative)
        .accessibilityHidden(true)
      Text("サーバーに接続できませんでした。")
        .font(.subheadline)
        .multilineTextAlignment(.center)
      Button("再試行") {
        Task { await model.load() }
      }
      .buttonStyle(OnboardingButtonStyle())
      .frame(maxWidth: 240)
      .padding(.top, 4)
    }
    .padding(.horizontal, 32)
  }

  // 아래로 당겨 다시 불러올 수 있게 스크롤 안에 둔다
  private func empty(_ model: HistoryModel) -> some View {
    ScrollView {
      VStack(spacing: 14) {
        Image(systemName: "chart.xyaxis.line")
          .font(.system(size: 44, weight: .light))
          .foregroundStyle(TechPalette.accent)
          .accessibilityHidden(true)
        Text("まだ記録がありません").font(.headline)
        Text("面接を最後まで終えると、ここに記録が表示されます。")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        Button("面接を始める", action: onStartInterview)
          .buttonStyle(OnboardingButtonStyle())
          .frame(maxWidth: 240)
          .padding(.top, 6)
      }
      .padding(.horizontal, 32)
      .frame(maxWidth: .infinity)
      .containerRelativeFrame(.vertical)
    }
    .scanRefreshable {
      await model.load()
      return !model.loadFailed
    }
  }

  private func list(_ model: HistoryModel) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Button {
          path.append(.analysis)
        } label: {
          SummaryCard(summary: model.summary)
        }
        .buttonStyle(.plain)
        HStack(spacing: 10) {
          Text(verbatim: "01")
            .font(.caption.monospacedDigit().weight(.bold))
            .foregroundStyle(TechPalette.accent)
          Text("過去の面接").font(.headline)
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        ForEach(HistoryAnalytics.monthGroups(model.interviews)) { group in
          monthSection(group)
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
    .scanRefreshable {
      await model.load()
      return !model.loadFailed
    }
  }

  private func monthSection(_ group: MonthGroup) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(group.month, format: .dateTime.year().month())
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
      VStack(spacing: 0) {
        ForEach(group.interviews) { interview in
          NavigationLink(value: HistoryRoute.result(interview.id)) {
            InterviewRow(interview: interview)
          }
          .buttonStyle(.plain)
          if interview.id != group.interviews.last?.id {
            Divider().padding(.leading, 16)
          }
        }
      }
      .background(TechCardBackground(showsBorder: false))
    }
  }
}

// 처음 불러오는 동안 요약 카드와 목록 자리에 빈 상자를 둔다
private struct HistorySkeleton: View {
  var body: some View {
    ScrollView {
      DotScanSkeleton {
        VStack(alignment: .leading, spacing: 20) {
          VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
              SkeletonBox(width: 132, height: 132, cornerRadius: 66)
              VStack(alignment: .leading, spacing: 10) {
                SkeletonBox(width: 96, height: 14)
                SkeletonBox(width: 76, height: 20, cornerRadius: 10)
                SkeletonBox(height: 72, cornerRadius: 10)
              }
            }
            SkeletonBox(height: 44, cornerRadius: 22)
          }
          .padding(16)
          HStack(spacing: 10) {
            SkeletonBox(width: 22, height: 12)
            SkeletonBox(width: 96, height: 16)
          }
          .padding(.horizontal, 4)
          VStack(alignment: .leading, spacing: 8) {
            SkeletonBox(width: 84, height: 11)
              .padding(.horizontal, 4)
            ForEach(0..<4, id: \.self) { _ in
              SkeletonBox(height: 64, cornerRadius: 16)
            }
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
    .scrollDisabled(true)
  }
}

private struct SummaryCard: View {
  let summary: HistorySummary

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top, spacing: 16) {
        ScoreGauge(value: summary.latest).frame(width: 132)
        VStack(alignment: .leading, spacing: 6) {
          Text("最新の総合点").font(.subheadline.weight(.semibold))
          if let difference = summary.difference {
            DifferenceBadge(difference: difference)
          }
          MiniTrendChart(points: summary.recentTotals).frame(height: 80)
        }
      }
      HStack {
        Label("分析を見る", systemImage: "chart.xyaxis.line")
        Spacer()
        Image(systemName: "chevron.right")
      }
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(TechPalette.accent)
      .padding(.horizontal, 16)
      .frame(minHeight: 44)
      .background(Capsule().fill(TechPalette.accent.opacity(0.1)))
    }
    .padding(16)
    .background(TechCardBackground())
    .contentShape(Rectangle())
  }
}

private struct DifferenceBadge: View {
  let difference: Double

  var body: some View {
    let tint = difference >= 0 ? TechPalette.positive : TechPalette.negative
    HStack(spacing: 4) {
      Image(systemName: difference >= 0 ? "arrow.up.right" : "arrow.down.right")
      Text("前回比 \(String(format: "%+.1f", difference))")
    }
    .font(.caption.monospaced().weight(.semibold))
    .foregroundStyle(tint)
    .padding(.horizontal, 8)
    .padding(.vertical, 3)
    .background(tint.opacity(0.12), in: Capsule())
    .overlay { Capsule().strokeBorder(tint.opacity(0.4)) }
  }
}

private struct InterviewRow: View {
  let interview: CompletedInterview

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text(interview.summary.companyName)
          .font(.headline)
          .lineLimit(1)
        HStack(spacing: 6) {
          LabelChip(text: interview.summary.interviewType.label)
          LabelChip(text: interview.summary.hiringType.label)
          Text(
            verbatim:
              "\(interview.summary.jobTitle)・\(interview.date.formatted(.dateTime.month().day()))"
          )
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
        }
      }
      Spacer(minLength: 8)
      score
      Image(systemName: "chevron.right")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.tertiary)
        .accessibilityHidden(true)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .contentShape(Rectangle())
  }

  @ViewBuilder
  private var score: some View {
    if let total = interview.scores?.total {
      HStack(alignment: .firstTextBaseline, spacing: 1) {
        Text(verbatim: String(format: "%.1f", total))
          .font(.title3.monospacedDigit().weight(.semibold))
        Text("点").font(.caption)
      }
    } else {
      Text("評価なし").font(.subheadline).foregroundStyle(.secondary)
    }
  }
}

private struct LabelChip: View {
  let text: String

  var body: some View {
    Text(text)
      .font(.caption2.weight(.semibold))
      .foregroundStyle(TechPalette.accent)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(Capsule().fill(TechPalette.accent.opacity(0.1)))
      .lineLimit(1)
      .fixedSize()
  }
}

#Preview {
  HistoryView()
}
