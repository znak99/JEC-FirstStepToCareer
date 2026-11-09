import SwiftUI

@main
struct FirstStepToCareerApp: App {
  var body: some Scene {
    WindowGroup {
      AppRootView()
        .environment(\.interviewDevices, SystemInterviewDevices())
    }
  }
}
