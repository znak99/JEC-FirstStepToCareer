import Charts
import SwiftUI

// 분석 화면의 날짜별 점수 추이. 손가락으로 끌면 가장 가까운 면접의 점수를 보여 준다
struct TrendChart: View {
  let points: [TrendPoint]
  let average: Double?

  @State private var progress = 0.0
  @State private var selectedDate: Date?

  private var selected: TrendPoint? {
    guard let selectedDate else { return nil }
    return points.min {
      abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
    }
  }

  var body: some View {
    Chart {
      ForEach(points) { point in
        AreaMark(x: .value("日付", point.date), y: .value("点", point.value * progress))
          .foregroundStyle(TechPalette.areaFill)
          .interpolationMethod(.monotone)
        LineMark(x: .value("日付", point.date), y: .value("点", point.value * progress))
          .foregroundStyle(TechPalette.accent)
          .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
          .interpolationMethod(.monotone)
          .shadow(color: TechPalette.accent.opacity(0.7), radius: 5)
        PointMark(x: .value("日付", point.date), y: .value("点", point.value * progress))
          .foregroundStyle(TechPalette.accent)
          .symbolSize(20)
      }
      if let average {
        RuleMark(y: .value("平均", average))
          .foregroundStyle(TechPalette.positive.opacity(0.9))
          .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
          .annotation(position: .top, alignment: .leading) {
            Text("平均 \(String(format: "%.1f", average))")
              .font(.caption2.monospaced())
              .foregroundStyle(TechPalette.positive)
          }
      }
      if let selected {
        RuleMark(x: .value("日付", selected.date))
          .foregroundStyle(TechPalette.ink.opacity(0.35))
          .annotation(
            position: .top, spacing: 4,
            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
          ) { readout(selected) }
        PointMark(x: .value("日付", selected.date), y: .value("点", selected.value))
          .foregroundStyle(TechPalette.accent)
          .symbolSize(140)
          .shadow(color: TechPalette.accent, radius: 8)
      }
    }
    .chartXSelection(value: $selectedDate)
    .chartYScale(domain: 0...100)
    .chartYAxis {
      AxisMarks(values: [0, 25, 50, 75, 100]) {
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
          .foregroundStyle(TechPalette.ink.opacity(0.2))
        AxisValueLabel().font(.caption2.monospaced())
      }
    }
    .chartXAxis {
      AxisMarks(values: .automatic(desiredCount: 4)) {
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
          .foregroundStyle(TechPalette.ink.opacity(0.12))
        AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
          .font(.caption2.monospaced())
      }
    }
    // 위쪽 여백은 손가락으로 고른 점수 표시가 들어갈 자리다
    .padding(.top, 56)
    .frame(height: 280)
    .reveal($progress, key: points)
  }

  private func readout(_ point: TrendPoint) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(point.date, format: .dateTime.year().month().day())
        .font(.caption2)
        .foregroundStyle(.secondary)
      Text(verbatim: String(format: "%.1f", point.value))
        .font(.callout.monospaced().weight(.semibold))
        .foregroundStyle(TechPalette.accent)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8).strokeBorder(TechPalette.accent.opacity(0.5))
    }
  }
}

// 기록 화면 요약 카드의 작은 추이. 간격을 고르게 하려고 날짜 대신 순번을 x로 쓴다
struct MiniTrendChart: View {
  let points: [TrendPoint]
  @State private var progress = 0.0

  var body: some View {
    let indexed = Array(points.enumerated())
    Chart {
      ForEach(indexed, id: \.element.id) { index, point in
        AreaMark(x: .value("回", index), y: .value("点", point.value * progress))
          .foregroundStyle(TechPalette.areaFill)
          .interpolationMethod(.monotone)
        LineMark(x: .value("回", index), y: .value("点", point.value * progress))
          .foregroundStyle(TechPalette.accent)
          .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
          .interpolationMethod(.monotone)
          .shadow(color: TechPalette.accent.opacity(0.7), radius: 4)
      }
      if let last = indexed.last {
        // 최신 점에 빛나는 테두리를 둔다
        PointMark(x: .value("回", last.offset), y: .value("点", last.element.value * progress))
          .foregroundStyle(TechPalette.accent.opacity(0.25))
          .symbolSize(160)
        PointMark(x: .value("回", last.offset), y: .value("点", last.element.value * progress))
          .foregroundStyle(TechPalette.accent)
          .symbolSize(30)
      }
    }
    .chartYScale(domain: 0...100)
    .chartXScale(domain: -0.3...Double(max(points.count - 1, 1)) + 0.3)
    .chartXAxis(.hidden)
    .chartYAxis {
      AxisMarks(values: [0, 50, 100]) {
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
          .foregroundStyle(TechPalette.ink.opacity(0.2))
        AxisValueLabel().font(.caption2.monospaced())
      }
    }
    .reveal($progress, key: points)
  }
}
