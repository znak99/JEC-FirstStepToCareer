import SwiftUI

// 기록 화면이 불러온 데이터로 기간별 추이, 강점·약점, 면접 종류·채용 구분별 평균을 보여 준다
struct AnalysisView: View {
  let interviews: [CompletedInterview]

  @State private var period = AnalysisPeriod.threeMonths
  @State private var metric = ScoreMetric.total

  var body: some View {
    let filtered = HistoryAnalytics.filter(interviews, period: period, now: Date())
    ScrollView {
      VStack(spacing: 16) {
        Picker("期間", selection: $period) {
          ForEach(AnalysisPeriod.allCases, id: \.self) { Text($0.label).tag($0) }
        }
        .pickerStyle(.segmented)
        if filtered.isEmpty {
          TechCard {
            ContentUnavailableView(
              "この期間の記録はありません", systemImage: "calendar.badge.exclamationmark")
          }
        } else {
          trendCard(filtered)
          strengthCard(filtered)
          groupCard(filtered)
        }
      }
      .padding(16)
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("分析")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func trendCard(_ interviews: [CompletedInterview]) -> some View {
    let points = HistoryAnalytics.trend(interviews, metric: metric)
    let average = HistoryAnalytics.average(points.map(\.value))
    return TechCard(title: "スコアの推移") {
      Picker("項目", selection: $metric) {
        ForEach(ScoreMetric.allCases, id: \.self) { Text($0.shortLabel).tag($0) }
      }
      .pickerStyle(.segmented)
      if points.isEmpty {
        Text("この項目は評価なしです").foregroundStyle(.secondary)
      } else {
        TrendChart(points: points, average: average)
        HStack(spacing: 12) {
          StatTile(title: "期間平均", value: ScoreFormat.text(average))
          StatTile(title: "面接回数", value: "\(points.count)回")
        }
      }
    }
  }

  private func strengthCard(_ interviews: [CompletedInterview]) -> some View {
    let averages = HistoryAnalytics.categoryAverages(interviews)
    let strengths = HistoryAnalytics.strengths(averages)
    return TechCard(title: "強みと弱み") {
      // 거미줄 모양은 꼭짓점이 3개 이상이어야 모양이 된다
      if averages.count >= 3 {
        RadarChart(
          axes: averages.map {
            RadarChart.Axis(
              id: $0.metric, label: $0.metric.label, value: $0.value,
              tint: tint(for: $0.metric, strengths: strengths))
          })
      } else {
        TechBarChart(
          rows: averages.map {
            TechBarChart.Row(
              label: $0.metric.label, value: $0.value, caption: String(format: "%.1f", $0.value),
              tint: strengths == nil ? nil : tint(for: $0.metric, strengths: strengths))
          })
      }
      if let strengths {
        HStack(spacing: 12) {
          StatTile(title: "強み", value: strengths.strongest.label, tint: TechPalette.positive)
          StatTile(title: "弱み", value: strengths.weakest.label, tint: TechPalette.negative)
        }
      }
      if !averages.contains(where: { $0.metric == .gaze }) {
        Text("視線・頭の動きを測定した面接がありません").font(.footnote).foregroundStyle(.secondary)
      }
    }
  }

  private func groupCard(_ interviews: [CompletedInterview]) -> some View {
    TechCard(title: "面接の種類・採用区分別") {
      Text("面接の種類").font(.caption).foregroundStyle(.secondary)
      TechBarChart(rows: rows(HistoryAnalytics.interviewTypeAverages(interviews)))
      Text("採用区分").font(.caption).foregroundStyle(.secondary)
      TechBarChart(rows: rows(HistoryAnalytics.hiringTypeAverages(interviews)))
    }
  }

  private func rows(_ groups: [GroupAverage]) -> [TechBarChart.Row] {
    groups.map { group in
      let caption =
        group.count == 0
        ? String(localized: "記録なし")
        : String(localized: "\(ScoreFormat.text(group.average))（\(group.count)回）")
      return TechBarChart.Row(label: group.label, value: group.average, caption: caption)
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

private struct StatTile: View {
  let title: LocalizedStringKey
  let value: String
  var tint: Color = TechPalette.accent

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
      Text(verbatim: value)
        .font(.headline.monospaced())
        .foregroundStyle(tint)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(tint.opacity(0.3)) }
  }
}
