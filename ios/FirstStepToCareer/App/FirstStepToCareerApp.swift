import SwiftUI

@main
struct FirstStepToCareerApp: App {
  private let useCases = AppContainer.makeUseCases()

  var body: some Scene {
    WindowGroup {
      AppRootView(useCases: useCases)
        .environment(\.useCases, useCases)
        .environment(\.appInfo, BuildConfig.appInfo)
        .environment(\.interviewDevices, SystemInterviewDevices())
    }
  }
}
