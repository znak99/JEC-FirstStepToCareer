import SwiftUI

// 앱을 켜면 스플래시를 먼저 보여 준다. 그 아래에는 처음이면 온보딩(동의 → 시작 → 정보 입력)을,
// 그 뒤에는 탭 화면을 둔다
struct AppRootView: View {
  private enum Stage {
    case consent, start, profile, tabs
  }

  @State private var hasStarted = AppSettings.hasStarted()
  @State private var hasAgreed = AppSettings.hasAgreed()
  @State private var choseStart = false
  @State private var showsSplash = true

  private var stage: Stage {
    if hasStarted { return .tabs }
    if !hasAgreed { return .consent }
    return choseStart ? .profile : .start
  }

  var body: some View {
    ZStack {
      Group {
        switch stage {
        case .consent:
          ConsentView {
            AppSettings.saveAgreement()
            hasAgreed = true
          }
          .transition(.opacity)
        case .start:
          StartView { choseStart = true }
            .transition(.opacity)
        case .profile:
          ProfileSetupView { profile in
            ProfileStore().save(profile)
            AppSettings.setHasStarted(true)
            hasStarted = true
          }
          .transition(.opacity)
        case .tabs:
          // 로그아웃·데이터 삭제 뒤에는 탭 화면을 버리고 다시 만들어 이전 계정의 화면 상태를 지운다
          RootTabView { reset() }
            .transition(.opacity)
        }
      }
      .animation(.easeInOut(duration: 0.3), value: stage)
      if showsSplash {
        SplashView(hasStarted: hasStarted) {
          withAnimation(.easeInOut(duration: 0.45)) { showsSplash = false }
        }
        .transition(
          .asymmetric(insertion: .identity, removal: .scale(scale: 1.12).combined(with: .opacity))
        )
        .zIndex(1)
      }
    }
    .task(id: showsSplash) {
      guard !showsSplash, SplashDebug.loops else { return }
      try? await Task.sleep(for: .seconds(1))
      showsSplash = true
    }
  }

  // 로그아웃·데이터 삭제 뒤에는 온보딩부터 다시 한다. 이전 계정의 면접이므로 남은 면접 ID도 지운다
  private func reset() {
    ActiveInterviewStore().clear()
    ProfileStore().clear()
    AppSettings.clearAgreement()
    AppSettings.setHasStarted(false)
    choseStart = false
    hasAgreed = false
    hasStarted = false
  }
}

#Preview {
  AppRootView()
}
