import Foundation
import Testing

@testable import FirstStepToCareer

struct AppSettingsTests {
  @Test func questionCountDefaultsAndClamps() throws {
    let defaults = try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)"))
    #expect(AppSettings.questionCount(in: defaults) == 5)
    AppSettings.setQuestionCount(9, in: defaults)
    #expect(AppSettings.questionCount(in: defaults) == 7)
    AppSettings.setQuestionCount(1, in: defaults)
    #expect(AppSettings.questionCount(in: defaults) == 3)
  }

  @Test func hasStartedDefaultsToFalseAndCanBeReset() throws {
    let defaults = try #require(UserDefaults(suiteName: "test.\(UUID().uuidString)"))
    #expect(AppSettings.hasStarted(in: defaults) == false)
    AppSettings.setHasStarted(true, in: defaults)
    #expect(AppSettings.hasStarted(in: defaults))
    AppSettings.setHasStarted(false, in: defaults)
    #expect(AppSettings.hasStarted(in: defaults) == false)
  }
}
