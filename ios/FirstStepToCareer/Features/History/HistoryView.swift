import SwiftUI

enum HistoryRoute: Hashable {
  case analysis
  case result(String)
}

struct HistoryView: View {
  @Environment(\.apiClient) private var api
  @State private var model: HistoryModel?
  @State private var path: [HistoryRoute] = []

  var body: some View {
    NavigationStack(path: $path) {
      Group {
        if let model {
          content(model)
        } else {
          ProgressView()
        }
      }
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
        ContentUnavailableView {
          Label("サーバーに接続できませんでした。", systemImage: "wifi.exclamationmark")
        } actions: {
          Button("再試行") { Task { await model.load() } }
        }
      } else {
        ProgressView()
      }
    } else if model.interviews.isEmpty {
      ContentUnavailableView(
        "まだ記録がありません", systemImage: "chart.xyaxis.line",
        description: Text("面接を最後まで終えると、ここに記録が表示されます。")
      )
      .refreshable { await model.load() }
    } else {
      // 요약 카드는 화면 높이의 약 1/3을 차지한다
      GeometryReader { proxy in
        List {
          Section {
            Button {
              path.append(.analysis)
            } label: {
              SummaryCard(summary: model.summary)
                .frame(height: proxy.size.height * 0.3)
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
          }
          Section("過去の面接") {
            ForEach(model.interviews) { interview in
              NavigationLink(value: HistoryRoute.result(interview.id)) {
                InterviewRow(interview: interview)
              }
            }
          }
        }
        .refreshable { await model.load() }
      }
    }
  }
}

private struct SummaryCard: View {
  let summary: HistorySummary

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 16) {
        ScoreGauge(value: summary.latest)
        VStack(alignment: .leading, spacing: 6) {
          Text("最新の総合点").font(.subheadline.weight(.semibold))
          if let difference = summary.difference {
            DifferenceBadge(difference: difference)
          }
          MiniTrendChart(points: summary.recentTotals)
        }
      }
      .frame(maxHeight: .infinity)
      HStack {
        Text("直近\(summary.recentTotals.count)回の総合点・タップで分析を見る")
        Spacer()
        Image(systemName: "chevron.right")
      }
      .font(.caption)
      .foregroundStyle(.secondary)
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
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(interview.summary.companyName).font(.headline)
        Text(
          "\(interview.summary.jobTitle)・\(interview.date.formatted(date: .abbreviated, time: .omitted))"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      Spacer()
      Text(ScoreFormat.text(interview.scores?.total))
        .font(.headline.monospacedDigit())
    }
  }
}

#Preview {
  HistoryView()
}
