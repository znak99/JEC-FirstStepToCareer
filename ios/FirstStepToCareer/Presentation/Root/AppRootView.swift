import SwiftUI

// 앱을 켜면 스플래시를 먼저 보여 준다. 그 아래에는 처음이면 온보딩(동의 → 시작 → 정보 입력)을,
// 그 뒤에는 탭 화면을 둔다. 어느 화면을 보여 줄지는 AppStage가 정한다
struct AppRootView: View {
  private let useCases: UseCases
  @State private var model: AppRootViewModel

  init(useCases: UseCases) {
    self.useCases = useCases
    _model = State(initialValue: AppRootViewModel(useCases))
  }

  private var asksAgreement: Binding<Bool> {
    Binding(get: { model.asksAgreement }, set: { _ in })
  }

  var body: some View {
    ZStack {
      Group {
        switch model.stage {
        case .consent:
          ConsentView(isUpdate: model.isConsentUpdate) { model.agree() }
            .transition(.opacity)
        case .start:
          StartView { model.choseStart() }
            .transition(.opacity)
        case .profile:
          // 동의 기록과 프로필은 정보 입력 화면이 서버와 이 iPhone에 저장한다
          ProfileSetupView { model.finishedProfile() }
            .transition(.opacity)
        case .tabs:
          // 로그아웃·데이터 삭제 뒤에는 탭 화면을 버리고 다시 만들어 이전 계정의 화면 상태를 지운다
          RootTabView { model.reset() }
            .transition(.opacity)
            .sheet(isPresented: asksAgreement) {
              // 동의해야만 닫힌다. 동의 기록은 이 모달에서 바로 서버에 남긴다
              ConsentView(step: nil, isUpdate: true, recordsOnServer: true) { model.agree() }
                .presentationDetents([.fraction(0.56)])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
            }
        }
      }
      .animation(.easeInOut(duration: 0.3), value: model.stage)
      if model.showsSplash {
        SplashView(hasStarted: model.hasStarted) {
          withAnimation(.easeInOut(duration: 0.45)) { model.showsSplash = false }
        }
        .transition(
          .asymmetric(insertion: .identity, removal: .scale(scale: 1.12).combined(with: .opacity))
        )
        .zIndex(1)
      }
    }
    .task(id: model.showsSplash) {
      guard !model.showsSplash, SplashDebug.loops else { return }
      try? await Task.sleep(for: .seconds(1))
      model.showsSplash = true
    }
  }
}
