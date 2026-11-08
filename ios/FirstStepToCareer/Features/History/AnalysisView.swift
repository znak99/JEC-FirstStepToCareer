import SwiftUI

// 기간 버튼, 총점 숫자 칸 4개, 「推移 / 強み・弱み / 種類別」 탭 (SITE_MAP S-12, 시안 B).
// 기록 화면이 불러온 데이터만 쓴다
struct AnalysisView: View {
  let interviews: [CompletedInterview]

  private enum Tab: CaseIterable {
    case trend
    case strengths
    case groups

    var title: LocalizedStringKey {
      switch self {
      case .trend: "推移"
      case .strengths: "強み・弱み"
      case .groups: "種類別"
      }
    }
  }

  @State private var period = AnalysisPeriod.threeMonths
  @State private var metric = ScoreMetric.total
  @State private var tab = Tab.trend

  var body: some View {
    let filtered = HistoryAnalytics.filter(interviews, period: period, now: Date())
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        PillPicker(items: AnalysisPeriod.allCases, selection: $period, title: \.label)
        if filtered.isEmpty {
          emptyCard
        } else {
          stats(HistoryAnalytics.periodStats(filtered))
          tabBar
          switch tab {
          case .trend: card { trend(filtered) }
          case .strengths: card { strengths(filtered) }
          case .groups: card { groups(filtered) }
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .padding(.bottom, 24)
    }
    .background { OnboardingBackground() }
    .reservesTabBarSpace()
    .navigationTitle("分析")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var emptyCard: some View {
    VStack(spacing: 10) {
      Image(systemName: "calendar.badge.exclamationmark")
        .font(.system(size: 36, weight: .light))
        .foregroundStyle(TechPalette.accent)
        .accessibilityHidden(true)
      Text("この期間の記録はありません").font(.headline)
    }
    .padding(24)
    .frame(maxWidth: .infinity)
    .background(TechCardBackground(showsBorder: false))
  }

  // MARK: 숫자 칸 (총점 기준)

  private func stats(_ stats: PeriodStats) -> some View {
    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
      StatCard(
        title: "期間平均", value: stats.average.map { String(format: "%.1f", $0) }, unit: "点",
        note: nil, tint: TechPalette.accent)
      StatCard(
        title: "面接回数", value: "\(stats.count)", unit: "回", note: nil, tint: TechPalette.accent)
      StatCard(
        title: "最高点", value: stats.best.map { String(format: "%.1f", $0.value) }, unit: "点",
        note: stats.best.map { $0.date.formatted(.dateTime.month().day()) },
        tint: TechPalette.positive)
      StatCard(
        title: "伸び", value: stats.growth.map { String(format: "%+.1f", $0) }, unit: "点",
        note: String(localized: "最初と最新の差"), tint: growthTint(stats.growth))
    }
  }

  private func growthTint(_ growth: Double?) -> Color {
    guard let growth, growth != 0 else { return TechPalette.accent }
    return growth > 0 ? TechPalette.positive : TechPalette.negative
  }

  // MARK: 탭

  private var tabBar: some View {
    HStack(spacing: 0) {
      ForEach(Tab.allCases, id: \.self) { item in
        let isOn = item == tab
        Button {
          tab = item
        } label: {
          VStack(spacing: 8) {
            Text(item.title)
              .font(.subheadline.weight(isOn ? .bold : .regular))
              .foregroundStyle(isOn ? TechPalette.accent : Color.secondary)
            Capsule()
              .fill(isOn ? TechPalette.accent : Color.clear)
              .frame(height: 3)
              .shadow(color: TechPalette.accent.opacity(isOn ? 0.7 : 0), radius: 4)
          }
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
      }
    }
    .overlay(alignment: .bottom) {
      Rectangle().fill(TechPalette.ink.opacity(0.1)).frame(height: 1)
    }
  }

  private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 14, content: content)
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(TechCardBackground(showsBorder: false))
  }

  @ViewBuilder
  private func trend(_ interviews: [CompletedInterview]) -> some View {
    let points = HistoryAnalytics.trend(interviews, metric: metric)
    PillPicker(
      items: ScoreMetric.allCases, selection: $metric, title: \.shortLabel, compact: true)
    if points.isEmpty {
      Text("この項目は評価なしです").foregroundStyle(.secondary)
    } else {
      TrendChart(points: points, average: HistoryAnalytics.average(points.map(\.value)))
      Text("グラフを指でなぞると、その日の点数が表示されます")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private func strengths(_ interviews: [CompletedInterview]) -> some View {
    let averages = HistoryAnalytics.categoryAverages(interviews)
    let strengths = HistoryAnalytics.strengths(averages)
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
      HStack(spacing: 10) {
        StrengthTile(title: "強み", value: strengths.strongest.label, tint: TechPalette.positive)
        StrengthTile(title: "弱み", value: strengths.weakest.label, tint: TechPalette.negative)
      }
    }
    if !averages.contains(where: { $0.metric == .gaze }) {
      Text("視線・頭の動きを測定した面接がありません").font(.footnote).foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private func groups(_ interviews: [CompletedInterview]) -> some View {
    Text("面接の種類").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
    TechBarChart(rows: rows(HistoryAnalytics.interviewTypeAverages(interviews)))
    Text("採用区分").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
    TechBarChart(rows: rows(HistoryAnalytics.hiringTypeAverages(interviews)))
  }

  // 평균이 서로 다르면 높은 쪽 막대를 초록으로 칠한다
  private func rows(_ groups: [GroupAverage]) -> [TechBarChart.Row] {
    let averages = groups.compactMap(\.average)
    let best = Set(averages).count > 1 ? averages.max() : nil
    return groups.map { group in
      let caption =
        group.count == 0
        ? String(localized: "記録なし")
        : String(localized: "\(ScoreFormat.text(group.average))（\(group.count)回）")
      return TechBarChart.Row(
        label: group.label, value: group.average, caption: caption,
        tint: best != nil && group.average == best ? TechPalette.positive : nil)
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

// 파란 그라데이션으로 고른 값을 표시하는 버튼 줄
private struct PillPicker<Item: Hashable>: View {
  let items: [Item]
  @Binding var selection: Item
  let title: (Item) -> String
  var compact = false

  var body: some View {
    HStack(spacing: compact ? 6 : 8) {
      ForEach(items, id: \.self) { item in
        let isOn = item == selection
        Button {
          selection = item
        } label: {
          Text(verbatim: title(item))
            .font((compact ? Font.caption : .subheadline).weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(isOn ? AnyShapeStyle(.white) : AnyShapeStyle(TechPalette.accent))
            .frame(maxWidth: .infinity, minHeight: compact ? 32 : 38)
            .background(
              Capsule().fill(
                isOn
                  ? AnyShapeStyle(
                    LinearGradient(
                      colors: [SplashPalette.top, SplashPalette.middle], startPoint: .topLeading,
                      endPoint: .bottomTrailing))
                  : AnyShapeStyle(TechPalette.cardTop))
            )
            .overlay {
              Capsule().strokeBorder(TechPalette.accent.opacity(isOn ? 0 : 0.35), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
      }
    }
  }
}

private struct StatCard: View {
  let title: LocalizedStringKey
  // 값이 없으면 「—」
  let value: String?
  let unit: LocalizedStringKey
  let note: String?
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
      HStack(alignment: .firstTextBaseline, spacing: 2) {
        if let value {
          Text(verbatim: value)
            .font(.system(size: 28, weight: .semibold, design: .monospaced))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
          Text(unit).font(.caption.weight(.semibold))
        } else {
          Text(verbatim: "—")
            .font(.system(size: 28, weight: .semibold, design: .monospaced))
            .foregroundStyle(.secondary)
        }
      }
      Text(verbatim: note ?? " ")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(TechCardBackground(showsBorder: false))
    .accessibilityElement(children: .combine)
  }
}

private struct StrengthTile: View {
  let title: LocalizedStringKey
  let value: String
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.caption).foregroundStyle(.secondary)
      Text(verbatim: value).font(.subheadline.weight(.semibold)).foregroundStyle(tint)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint.opacity(0.1)))
    .accessibilityElement(children: .combine)
  }
}
