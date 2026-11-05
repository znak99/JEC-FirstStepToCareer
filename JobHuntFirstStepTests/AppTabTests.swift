import Testing

@testable import JobHuntFirstStep

struct AppTabTests {
  @Test func tabsFollowTheSiteMapOrder() {
    #expect(AppTab.allCases == [.interview, .schedule, .analytics])
  }
}
