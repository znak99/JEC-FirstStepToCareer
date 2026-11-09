import SwiftUI

// 앱을 켜면 스플래시를 먼저 보여 준다. 그 아래에는 처음이면 온보딩(동의 → 시작 → 정보 입력)을,
// 그 뒤에는 탭 화면을 둔다. 어느 화면을 보여 줄지는 AppStage가 정한다
struct AppRootView: View {
  @State private var hasStarted = AppSettings.hasStarted()
  @State private var hasAgreed = AppSettings.hasAgreed()
  @State private var choseStart = AppSettings.hasChosenStart()
  @State private var hasProfile = ProfileStore().profile != nil
  @State private var showsSplash = true

  private var stage: AppStage {
    AppStage.of(
      hasAgreed: hasAgreed, hasStarted: hasStarted, choseStart: choseStart, hasProfile: hasProfile)
  }

  // 약관 버전이 바뀌었으면 스플래시가 끝난 뒤 탭 화면 위에 동의 모달을 띄운다
  private var asksAgreement: Binding<Bool> {
    Binding(
      get: {
        !showsSplash
          && AppStage.asksAgreementOverTabs(
            hasAgreed: hasAgreed, hasStarted: hasStarted, hasProfile: hasProfile)
      }, set: { _ in })
  }

  var body: some View {
    ZStack {
      Group {
        switch stage {
        case .consent:
          ConsentView(isUpdate: AppSettings.hasOutdatedAgreement()) {
            AppSettings.saveAgreement()
            hasAgreed = true
          }
          .transition(.opacity)
        case .start:
          StartView {
            AppSettings.setHasChosenStart(true)
            choseStart = true
          }
          .transition(.opacity)
        case .profile:
          // 동의 기록과 프로필은 정보 입력 화면이 서버와 이 iPhone에 저장한다
          ProfileSetupView {
            AppSettings.setHasStarted(true)
            hasProfile = true
            hasStarted = true
          }
          .transition(.opacity)
        case .tabs:
          // 로그아웃·데이터 삭제 뒤에는 탭 화면을 버리고 다시 만들어 이전 계정의 화면 상태를 지운다
          RootTabView { reset() }
            .transition(.opacity)
            .sheet(isPresented: asksAgreement) {
              // 동의해야만 닫힌다. 동의 기록은 이 모달에서 바로 서버에 남긴다
              ConsentView(step: nil, isUpdate: true, recordsOnServer: true) {
                AppSettings.saveAgreement()
                hasAgreed = true
              }
              .presentationDetents([.fraction(0.56)])
              .presentationDragIndicator(.hidden)
              .interactiveDismissDisabled()
            }
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
    AppSettings.setHasChosenStart(false)
    AppSettings.setHasStarted(false)
    choseStart = false
    hasProfile = false
    hasAgreed = false
    hasStarted = false
  }
}

#Preview {
  AppRootView()
}
