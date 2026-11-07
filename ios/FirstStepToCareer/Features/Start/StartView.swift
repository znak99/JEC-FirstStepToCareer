import SwiftUI

// 첫 실행과 로그아웃·데이터 삭제 후에 보여 준다 (SITE_MAP S-00)
struct StartView: View {
  var onStarted: () -> Void = {}

  @Environment(\.apiClient) private var api
  @State private var model: StartModel?
  @State private var showsPrivacy = false

  var body: some View {
    ZStack {
      background
      if let model {
        content(model)
      }
    }
    .task { if model == nil { model = StartModel(api: api) } }
    .sheet(isPresented: $showsPrivacy) {
      NavigationStack {
        PrivacyView()
          .toolbar {
            ToolbarItem(placement: .confirmationAction) {
              Button("閉じる") { showsPrivacy = false }
            }
          }
      }
    }
  }

  private var background: some View {
    LinearGradient(
      colors: [TechPalette.pageTop, TechPalette.pageBottom], startPoint: .top,
      endPoint: .bottom
    )
    .overlay { DotGrid() }
    .ignoresSafeArea()
  }

  private func content(_ model: StartModel) -> some View {
    @Bindable var model = model
    return VStack(spacing: 0) {
      Spacer()
      header
      Spacer()
      features
      Spacer()
      actions(model)
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 12)
    .disabled(model.isSigningIn)
    .overlay {
      if model.isSigningIn { ProgressView().controlSize(.large) }
    }
    .alert("ログインできませんでした", isPresented: $model.signInFailed) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("しばらくしてから、もう一度お試しください。")
    }
  }

  private var header: some View {
    VStack(spacing: 16) {
      // 앱 아이콘과 같은 그림. 홈 화면 아이콘처럼 모서리를 둥글게 자른다
      Image("AppLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 112, height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: TechPalette.accent.opacity(0.5), radius: 16)
        .accessibilityHidden(true)
      Text("就活一歩")
        .font(.system(size: 34, weight: .bold))
      Text("就職・転職活動のための模擬面接")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }

  private var features: some View {
    VStack(alignment: .leading, spacing: 14) {
      feature("AIと本番さながらの模擬面接", systemImage: "sparkles")
      feature("声で答えると、その場で文字に", systemImage: "waveform")
      feature("点数とフィードバックで振り返り", systemImage: "chart.line.uptrend.xyaxis")
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(TechCardBackground())
  }

  private func feature(_ text: LocalizedStringKey, systemImage: String) -> some View {
    Label {
      Text(text).font(.callout.weight(.medium))
    } icon: {
      Image(systemName: systemImage)
        .foregroundStyle(TechPalette.accent)
        .frame(width: 24)
    }
  }

  private func actions(_ model: StartModel) -> some View {
    VStack(spacing: 12) {
      if BuildConfig.appleSignInEnabled {
        AppleSignInButton { request in
          Task { if await model.signIn(request) { onStarted() } }
        } onFailed: {
          model.reportSignInFailure()
        }
        .clipShape(Capsule())
      }
      Button {
        onStarted()
      } label: {
        Text("ログインなしで始める")
          .font(.headline)
          // 어두운 모드의 밝은 파랑 버튼에서도 글자가 잘 보이게 한다
          .foregroundStyle(TechPalette.cardBottom)
          // Apple 로그인 버튼과 높이를 맞춘다
          .frame(maxWidth: .infinity, minHeight: 44)
          .background(Capsule().fill(TechPalette.accent))
          .shadow(color: TechPalette.accent.opacity(0.5), radius: 8)
          .contentShape(Capsule())
      }
      .buttonStyle(.plain)
      Button("個人情報の取り扱い") { showsPrivacy = true }
        .font(.footnote)
        .padding(.top, 4)
    }
  }
}

#Preview {
  StartView()
}
