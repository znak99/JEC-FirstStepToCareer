import Charts
import SwiftUI

// 기록 화면이 불러온 데이터로 기간별 추이, 강점·약점, 면접 종류·채용 구분별 평균을 보여 준다
struct AnalysisView: View {
  let interviews: [CompletedInterview]

  @State private var period = AnalysisPeriod.threeMonths
  @State private var metric = ScoreMetric.total

  var body: some View {
    let filtered = HistoryAnalytics.filter(interviews, period: period, now: Date())
    List {
      Section {
        Picker("期間", selection: $period) {
          ForEach(AnalysisPeriod.allCases, id: \.self) { Text($0.label).tag($0) }
        }
        .pickerStyle(.segmented)
      }
      if filtered.isEmpty {
        Section {
          ContentUnavailableView(
            "この期間の記録はありません", systemImage: "calendar.badge.exclamationmark")
        }
      } else {
        trendSection(filtered)
        strengthSection(filtered)
        groupSection(filtered)
      }
    }
    .navigationTitle("分析")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func trendSection(_ interviews: [CompletedInterview]) -> some View {
    let points = HistoryAnalytics.trend(interviews, metric: metric)
    return Section("スコアの推移") {
      Picker("項目", selection: $metric) {
        ForEach(ScoreMetric.allCases, id: \.self) { Text($0.shortLabel).tag($0) }
      }
      .pickerStyle(.segmented)
      if points.isEmpty {
        Text("この項目は評価なしです").foregroundStyle(.secondary)
      } else {
        Chart(points) { point in
          LineMark(x: .value("日付", point.date), y: .value("点", point.value))
          PointMark(x: .value("日付", point.date), y: .value("点", point.value))
        }
        .chartYScale(domain: 0...100)
        .frame(height: 200)
        LabeledContent(
          "期間平均", value: ScoreFormat.text(HistoryAnalytics.average(points.map(\.value))))
        LabeledContent("面接回数", value: "\(points.count)回")
      }
    }
  }

  private func strengthSection(_ interviews: [CompletedInterview]) -> some View {
    let averages = HistoryAnalytics.categoryAverages(interviews)
    let strengths = HistoryAnalytics.strengths(averages)
    return Section("強みと弱み") {
      Chart(averages) { average in
        BarMark(x: .value("点", average.value), y: .value("項目", average.metric.label))
          .foregroundStyle(color(for: average.metric, strengths: strengths))
          .annotation(position: .trailing) {
            Text(String(format: "%.1f", average.value)).font(.caption)
          }
      }
      .chartXScale(domain: 0...100)
      .chartXAxis { AxisMarks(values: [0, 25, 50, 75, 100]) }
      .frame(height: CGFloat(averages.count) * 44)
      if let strengths {
        LabeledContent("強み", value: strengths.strongest.label)
        LabeledContent("弱み", value: strengths.weakest.label)
      }
      if !averages.contains(where: { $0.metric == .gaze }) {
        Text("視線・頭の動きを測定した面接がありません").font(.footnote).foregroundStyle(.secondary)
      }
    }
  }

  private func groupSection(_ interviews: [CompletedInterview]) -> some View {
    Section("面接の種類・採用区分別") {
      ForEach(
        HistoryAnalytics.interviewTypeAverages(interviews)
          + HistoryAnalytics.hiringTypeAverages(interviews)
      ) { group in
        LabeledContent(group.label) {
          if group.count == 0 {
            Text("記録なし")
          } else {
            Text("\(ScoreFormat.text(group.average))（\(group.count)回）")
          }
        }
      }
    }
  }

  private func color(
    for metric: ScoreMetric, strengths: (strongest: ScoreMetric, weakest: ScoreMetric)?
  ) -> Color {
    if metric == strengths?.strongest { return .green }
    if metric == strengths?.weakest { return .orange }
    return .accentColor
  }
}
