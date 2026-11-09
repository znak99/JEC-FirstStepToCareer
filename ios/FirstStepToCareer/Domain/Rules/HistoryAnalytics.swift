import Foundation

// 기록 탭의 요약과 분석 화면 계산. 서버의 목록 응답만으로 앱에서 계산한다
enum ScoreMetric: CaseIterable, Hashable, Sendable {
  case total
  case structure
  case logic
  case gaze
  case head

  static let categories: [ScoreMetric] = [.structure, .logic, .gaze, .head]

  var shortLabel: String {
    switch self {
    case .total: String(localized: "総合")
    case .structure: String(localized: "構成")
    case .logic: String(localized: "論理")
    case .gaze: String(localized: "視線")
    case .head: String(localized: "頭")
    }
  }

  var label: String {
    switch self {
    case .total: String(localized: "総合点")
    case .structure: String(localized: "回答の構成")
    case .logic: String(localized: "回答の論理")
    case .gaze: String(localized: "視線の動き")
    case .head: String(localized: "頭の動き")
    }
  }

  func value(in scores: InterviewScores?) -> Double? {
    switch self {
    case .total: scores?.total
    case .structure: scores?.structure
    case .logic: scores?.logic
    case .gaze: scores?.gaze
    case .head: scores?.head
    }
  }
}

enum AnalysisPeriod: CaseIterable, Hashable, Sendable {
  case oneMonth
  case threeMonths
  case all

  var label: String {
    switch self {
    case .oneMonth: String(localized: "1か月")
    case .threeMonths: String(localized: "3か月")
    case .all: String(localized: "全期間")
    }
  }

  func start(now: Date, calendar: Calendar = .current) -> Date? {
    switch self {
    case .oneMonth: calendar.date(byAdding: .month, value: -1, to: now)
    case .threeMonths: calendar.date(byAdding: .month, value: -3, to: now)
    case .all: nil
    }
  }
}

// 평가가 끝난 면접. 날짜는 끝난 시각(없으면 시작 시각)이다
struct CompletedInterview: Identifiable, Equatable, Sendable {
  let summary: InterviewSummary
  let date: Date

  var id: String { summary.id }
  var scores: InterviewScores? { summary.scores }

  // 평가가 끝난 면접만 골라 최신순으로 정렬한다
  static func list(from summaries: [InterviewSummary]) -> [CompletedInterview] {
    summaries
      .filter { $0.status == .completed }
      .compactMap { summary in
        parseDate(summary.completedAt ?? summary.startedAt).map {
          CompletedInterview(summary: summary, date: $0)
        }
      }
      .sorted { $0.date > $1.date }
  }

  static func parseDate(_ value: String) -> Date? {
    (try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(value))
      ?? (try? Date.ISO8601FormatStyle().parse(value))
  }
}

struct TrendPoint: Identifiable, Equatable, Sendable {
  let id: String
  let date: Date
  let value: Double
}

struct HistorySummary: Equatable, Sendable {
  let latest: Double?
  let difference: Double?
  // 오래된 순
  let recentTotals: [TrendPoint]

  static let recentCount = 10

  // interviews는 최신순이다
  init(interviews: [CompletedInterview]) {
    let totals = interviews.compactMap { interview in
      interview.scores?.total.map { TrendPoint(id: interview.id, date: interview.date, value: $0) }
    }
    latest = totals.first?.value
    difference = totals.count >= 2 ? totals[0].value - totals[1].value : nil
    recentTotals = Array(totals.prefix(Self.recentCount).reversed())
  }
}

// 기록 화면에서 한 달에 끝난 면접들
struct MonthGroup: Identifiable, Equatable, Sendable {
  // 그 달의 첫날 0시
  let month: Date
  let interviews: [CompletedInterview]
  var id: Date { month }
}

struct CategoryAverage: Identifiable, Equatable, Sendable {
  let metric: ScoreMetric
  let value: Double
  var id: ScoreMetric { metric }
}

// 분석 화면 위쪽 숫자 칸. 모두 총점 기준이다
struct PeriodStats: Equatable, Sendable {
  let average: Double?
  let count: Int
  let best: TrendPoint?
  // 기간 안의 첫 면접과 최근 면접의 총점 차이. 면접이 1번뿐이면 nil
  let growth: Double?
}

struct GroupAverage: Identifiable, Equatable, Sendable {
  let label: String
  let average: Double?
  let count: Int
  var id: String { label }
}

enum HistoryAnalytics {
  static func filter(_ interviews: [CompletedInterview], period: AnalysisPeriod, now: Date)
    -> [CompletedInterview]
  {
    guard let start = period.start(now: now) else { return interviews }
    return interviews.filter { $0.date >= start }
  }

  static func average(_ values: [Double]) -> Double? {
    values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
  }

  // 오래된 순. 점수가 없는 면접(측정하지 않은 시선·머리)은 뺀다
  static func trend(_ interviews: [CompletedInterview], metric: ScoreMetric) -> [TrendPoint] {
    interviews
      .compactMap { interview in
        metric.value(in: interview.scores).map {
          TrendPoint(id: interview.id, date: interview.date, value: $0)
        }
      }
      .sorted { $0.date < $1.date }
  }

  static func periodStats(_ interviews: [CompletedInterview]) -> PeriodStats {
    let points = trend(interviews, metric: .total)
    return PeriodStats(
      average: average(points.map(\.value)),
      count: interviews.count,
      best: points.max { $0.value < $1.value },
      growth: points.count >= 2 ? points[points.count - 1].value - points[0].value : nil)
  }

  static func categoryAverages(_ interviews: [CompletedInterview]) -> [CategoryAverage] {
    ScoreMetric.categories.compactMap { metric in
      average(interviews.compactMap { metric.value(in: $0.scores) }).map {
        CategoryAverage(metric: metric, value: $0)
      }
    }
  }

  // 최신순 목록을 달별로 묶는다. 묶음과 묶음 안의 순서는 그대로 둔다
  static func monthGroups(_ interviews: [CompletedInterview], calendar: Calendar = .current)
    -> [MonthGroup]
  {
    var groups: [MonthGroup] = []
    for interview in interviews {
      let month = calendar.dateInterval(of: .month, for: interview.date)?.start ?? interview.date
      if let last = groups.last, last.month == month {
        groups[groups.count - 1] = MonthGroup(
          month: month, interviews: last.interviews + [interview])
      } else {
        groups.append(MonthGroup(month: month, interviews: [interview]))
      }
    }
    return groups
  }

  // 면접 하나의 항목별 점수. 재지 않은 항목(시선·머리)은 뺀다
  static func categoryScores(_ scores: InterviewScores?) -> [CategoryAverage] {
    ScoreMetric.categories.compactMap { metric in
      metric.value(in: scores).map { CategoryAverage(metric: metric, value: $0) }
    }
  }

  // 항목이 둘 이상이고 평균이 모두 같지 않을 때만 강점·약점을 정한다
  static func strengths(_ averages: [CategoryAverage]) -> (
    strongest: ScoreMetric, weakest: ScoreMetric
  )? {
    guard averages.count >= 2,
      let strongest = averages.max(by: { $0.value < $1.value }),
      let weakest = averages.min(by: { $0.value < $1.value }),
      strongest.value > weakest.value
    else { return nil }
    return (strongest.metric, weakest.metric)
  }

  static func interviewTypeAverages(_ interviews: [CompletedInterview]) -> [GroupAverage] {
    [InterviewType.hr, .job].map { type in
      group(type.label, interviews.filter { $0.summary.interviewType == type })
    }
  }

  static func hiringTypeAverages(_ interviews: [CompletedInterview]) -> [GroupAverage] {
    [HiringType.newGrad, .midCareer].map { type in
      group(type.label, interviews.filter { $0.summary.hiringType == type })
    }
  }

  private static func group(_ label: String, _ interviews: [CompletedInterview]) -> GroupAverage {
    GroupAverage(
      label: label, average: average(interviews.compactMap { $0.scores?.total }),
      count: interviews.count)
  }
}
