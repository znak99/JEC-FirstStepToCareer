import Testing

@testable import FirstStepToCareer

struct AppTabTests {
  @Test func tabsFollowTheSiteMapOrder() {
    #expect(AppTab.allCases == [.interview, .history, .menu])
  }
}
