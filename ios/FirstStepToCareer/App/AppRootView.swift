import SwiftUI

// 시작 화면을 지나가기 전에는 시작 화면을, 그 뒤에는 탭 화면을 보여 준다
struct AppRootView: View {
  @State private var hasStarted = AppSettings.hasStarted()

  var body: some View {
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
  }

  private func setStarted(_ value: Bool) {
    AppSettings.setHasStarted(value)
    hasStarted = value
  }
}

#Preview {
  AppRootView()
}
