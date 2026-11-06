import Foundation
import Testing

@testable import FirstStepToCareer

struct HistoryAnalyticsTests {
  static let now = CompletedInterview.parseDate("2026-11-06T12:00:00.000Z")!

  static func summary(
    _ id: String, daysAgo: Int, status: InterviewStatus = .completed, total: Double? = 70,
    structure: Double? = 70, logic: Double? = 70, gaze: Double? = nil, head: Double? = nil,
    type: InterviewType = .hr, hiring: HiringType = .newGrad
  ) -> InterviewSummary {
    let date = now.addingTimeInterval(-Double(daysAgo) * 86_400)
    let text = date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    return InterviewSummary(
      id: id, companyName: "会社\(id)", industry: "IT", jobTitle: "エンジニア", interviewType: type,
      hiringType: hiring, status: status, startedAt: text,
      completedAt: status == .completed ? text : nil,
      scores: status == .completed
        ? InterviewScores(total: total, structure: structure, logic: logic, gaze: gaze, head: head)
        : nil)
  }

  static func completed(_ summaries: [InterviewSummary]) -> [CompletedInterview] {
    CompletedInterview.list(from: summaries)
  }

  @Test func keepsOnlyCompletedNewestFirst() {
    let list = Self.completed([
      Self.summary("old", daysAgo: 10), Self.summary("progress", daysAgo: 0, status: .inProgress),
      Self.summary("waiting", daysAgo: 1, status: .awaitingEvaluation),
      Self.summary("new", daysAgo: 2),
    ])
    #expect(list.map(\.id) == ["new", "old"])
  }

  @Test func parsesDatesWithAndWithoutFractionalSeconds() {
    #expect(CompletedInterview.parseDate("2026-11-06T09:25:18.542Z") != nil)
    #expect(CompletedInterview.parseDate("2026-11-06T09:25:18Z") != nil)
    #expect(CompletedInterview.parseDate("2026/11/06") == nil)
  }

  @Test func summaryShowsLatestDifferenceAndRecentTen() {
    let list = Self.completed(
      (0..<12).map { Self.summary("\($0)", daysAgo: $0, total: Double(80 - $0)) })
    let summary = HistorySummary(interviews: list)
    #expect(summary.latest == 80)
    #expect(summary.difference == 1)
    #expect(summary.recentTotals.count == 10)
    // 그래프는 오래된 순이라 마지막이 최신이다
    #expect(summary.recentTotals.last?.value == 80)
    #expect(summary.recentTotals.first?.value == 71)
  }

  @Test func summaryWithOneInterviewHasNoDifference() {
    let summary = HistorySummary(interviews: Self.completed([Self.summary("a", daysAgo: 0)]))
    #expect(summary.latest == 70)
    #expect(summary.difference == nil)
    #expect(HistorySummary(interviews: []).latest == nil)
  }

  @Test func filtersByPeriod() {
    let list = Self.completed([
      Self.summary("a", daysAgo: 5), Self.summary("b", daysAgo: 40),
      Self.summary("c", daysAgo: 200),
    ])
    let ids = { (period: AnalysisPeriod) in
      HistoryAnalytics.filter(list, period: period, now: Self.now).map(\.id)
    }
    #expect(ids(.oneMonth) == ["a"])
    #expect(ids(.threeMonths) == ["a", "b"])
    #expect(ids(.all) == ["a", "b", "c"])
  }

  @Test func trendSkipsUnmeasuredAndIsOldestFirst() {
    let list = Self.completed([
      Self.summary("a", daysAgo: 1, gaze: 90), Self.summary("b", daysAgo: 2),
      Self.summary("c", daysAgo: 3, gaze: 80),
    ])
    let points = HistoryAnalytics.trend(list, metric: .gaze)
    #expect(points.map(\.id) == ["c", "a"])
    #expect(HistoryAnalytics.average(points.map(\.value)) == 85)
    #expect(HistoryAnalytics.average([]) == nil)
  }

  @Test func categoryAveragesAndStrengths() {
    let list = Self.completed([
      Self.summary("a", daysAgo: 1, structure: 90, logic: 60, gaze: 80, head: nil),
      Self.summary("b", daysAgo: 2, structure: 70, logic: 80, gaze: nil, head: nil),
    ])
    let averages = HistoryAnalytics.categoryAverages(list)
    #expect(averages.map(\.metric) == [.structure, .logic, .gaze])
    #expect(averages.map(\.value) == [80, 70, 80])
    let strengths = HistoryAnalytics.strengths(averages)
    #expect(strengths?.weakest == .logic)
    #expect(strengths?.strongest == .structure)
  }

  @Test func noStrengthsWhenAllEqualOrSingle() {
    let equal = [
      CategoryAverage(metric: .structure, value: 70), CategoryAverage(metric: .logic, value: 70),
    ]
    #expect(HistoryAnalytics.strengths(equal) == nil)
    #expect(HistoryAnalytics.strengths([CategoryAverage(metric: .logic, value: 70)]) == nil)
  }

  @Test func groupAveragesIncludeEmptyGroups() {
    let list = Self.completed([
      Self.summary("a", daysAgo: 1, total: 80, type: .hr),
      Self.summary("b", daysAgo: 2, total: 60, type: .hr),
      Self.summary("c", daysAgo: 3, total: 90, type: .job, hiring: .newGrad),
    ])
    let types = HistoryAnalytics.interviewTypeAverages(list)
    #expect(types.map(\.label) == ["人事面接", "職務面接"])
    #expect(types.map(\.average) == [70, 90])
    #expect(types.map(\.count) == [2, 1])
    let hiring = HistoryAnalytics.hiringTypeAverages(list)
    #expect(hiring.map(\.count) == [3, 0])
    #expect(hiring[1].average == nil)
  }
}

// StubURLProtocol을 함께 쓰므로 APIClientTests와 같은 직렬 실행 묶음에 둔다
extension APIClientTests {
  @MainActor
  @Test func historyModelLoadsAllPages() async throws {
    let first = InterviewPage(
      items: [HistoryAnalyticsTests.summary("a", daysAgo: 1)], nextCursor: "next")
    let second = InterviewPage(
      items: [
        HistoryAnalyticsTests.summary("b", daysAgo: 2),
        HistoryAnalyticsTests.summary("c", daysAgo: 0, status: .inProgress),
      ], nextCursor: nil)
    let firstData = try JSONEncoder().encode(first)
    let secondData = try JSONEncoder().encode(second)
    StubURLProtocol.handler = { request in
      request.url?.query?.contains("cursor=next") == true ? (200, secondData) : (200, firstData)
    }
    let model = HistoryModel(api: client)
    await model.load()
    #expect(model.hasLoaded)
    #expect(!model.loadFailed)
    #expect(model.interviews.map(\.id) == ["a", "b"])
  }

  @MainActor
  @Test func historyModelKeepsDataWhenReloadFails() async throws {
    let page = InterviewPage(
      items: [HistoryAnalyticsTests.summary("a", daysAgo: 1)], nextCursor: nil)
    let data = try JSONEncoder().encode(page)
    StubURLProtocol.handler = { _ in (200, data) }
    let model = HistoryModel(api: client)
    await model.load()
    StubURLProtocol.handler = { _ in (500, Data(#"{"error":{"code":"INTERNAL_ERROR"}}"#.utf8)) }
    await model.load()
    #expect(model.loadFailed)
    #expect(model.interviews.map(\.id) == ["a"])
  }
}
