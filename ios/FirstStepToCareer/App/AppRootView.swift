import SwiftUI

// 앱을 켜면 스플래시를 먼저 보여 준다. 그 아래에는 시작 화면을 지나가기 전에는 시작 화면을, 그 뒤에는 탭 화면을 둔다
struct AppRootView: View {
  @State private var hasStarted = AppSettings.hasStarted()
  @State private var showsSplash = true

  var body: some View {
    ZStack {
      Group {
        if hasStarted {
          // 로그아웃·데이터 삭제 뒤에는 탭 화면을 버리고 다시 만들어 이전 계정의 화면 상태를 지운다
          RootTabView { setStarted(false) }
            .transition(.opacity)
        } else {
          StartView { setStarted(true) }
            .transition(.opacity)
        }
      }
      .animation(.easeInOut(duration: 0.3), value: hasStarted)
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

  private func setStarted(_ value: Bool) {
    // 로그아웃·데이터 삭제 뒤에는 이전 계정의 면접이므로 지울 필요가 없다
    if !value { ActiveInterviewStore().clear() }
    AppSettings.setHasStarted(value)
    hasStarted = value
  }
}

#Preview {
  AppRootView()
}
