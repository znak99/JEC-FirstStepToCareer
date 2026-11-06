import Charts
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
            NavigationLink(value: HistoryRoute.analysis) {
              SummaryCard(summary: model.summary)
                .frame(height: proxy.size.height * 0.3)
            }
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
    VStack(alignment: .leading, spacing: 8) {
      Text("最新の総合点").font(.subheadline).foregroundStyle(.secondary)
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text(ScoreFormat.text(summary.latest))
          .font(.system(size: 36, weight: .bold))
        if let difference = summary.difference {
          Text("前回比 \(String(format: "%+.1f", difference))")
            .font(.subheadline.bold())
            .foregroundStyle(difference >= 0 ? .green : .red)
        }
      }
      Chart(Array(summary.recentTotals.enumerated()), id: \.element.id) { index, point in
        LineMark(x: .value("回", index), y: .value("点", point.value))
        PointMark(x: .value("回", index), y: .value("点", point.value))
      }
      .chartYScale(domain: 0...100)
      .chartXAxis(.hidden)
      .chartYAxis {
        AxisMarks(values: [0, 50, 100])
      }
      .frame(maxHeight: .infinity)
      // 그래프가 탭을 가로채지 않게 해 카드 어디를 눌러도 분석 화면으로 가게 한다
      .allowsHitTesting(false)
      Text("直近\(summary.recentTotals.count)回の総合点・タップで分析を見る")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
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
