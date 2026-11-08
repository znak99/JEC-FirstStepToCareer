import SwiftUI

enum MenuRoute: Hashable {
  case profile
  case terms
  case privacy
  case appInfo
}

// 번호 카드와 아이콘 줄 (SITE_MAP S-09, 시안 A)
struct MenuView: View {
  // 로그아웃·데이터 삭제가 끝났을 때 부른다. 온보딩부터 다시 한다
  var onReset: () -> Void = {}

  @Environment(\.apiClient) private var api
  @State private var model: MenuModel?
  @State private var confirmsDelete = false
  @State private var confirmsSignOut = false
  // 프로필 줄에 보여 줄 이름. 프로필 화면에서 돌아오면 다시 읽는다
  @State private var nickname = ProfileStore().profile?.nickname

  var body: some View {
    NavigationStack {
      Group {
        if let model {
          content(model)
        } else {
          ProgressView()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background { OnboardingBackground() }
      .navigationTitle("メニュー")
      .onAppear { nickname = ProfileStore().profile?.nickname }
      .navigationDestination(for: MenuRoute.self) { route in
        switch route {
        case .profile: ProfileEditView()
        case .terms: LegalDocumentView(document: .terms)
        case .privacy: LegalDocumentView(document: .privacy)
        case .appInfo: AppInfoView()
        }
      }
      .task {
        let current = model ?? MenuModel(api: api)
        model = current
        await current.loadAccount()
      }
    }
  }

  private func content(_ model: MenuModel) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        section(1, "プロフィール") {
          NavigationLink(value: MenuRoute.profile) {
            MenuRow(icon: "person.fill", title: "お名前（ニックネーム）") {
              if let nickname { Text(nickname) } else { Text("未設定") }
            }
          }
          .buttonStyle(.plain)
        }
        section(2, "アカウント") { accountCard(model) }
        section(3, "情報") {
          NavigationLink(value: MenuRoute.terms) {
            MenuRow(icon: "doc.text.fill", title: "利用規約")
          }
          .buttonStyle(.plain)
          Divider().padding(.leading, 60)
          NavigationLink(value: MenuRoute.privacy) {
            MenuRow(icon: "hand.raised.fill", title: "プライバシーポリシー")
          }
          .buttonStyle(.plain)
          Divider().padding(.leading, 60)
          NavigationLink(value: MenuRoute.appInfo) {
            MenuRow(icon: "info.circle.fill", title: "アプリ情報")
          }
          .buttonStyle(.plain)
        }
        VStack(alignment: .leading, spacing: 8) {
          OutlineButton(title: "すべてのデータを削除", icon: "trash", tint: TechPalette.negative) {
            confirmsDelete = true
          }
          Text("サーバーに保存された面接の記録をすべて削除します。元に戻すことはできません。")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
        }
        .padding(.top, 4)
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
    .disabled(model.isWorking)
    .loadingOverlay(model.isWorking, message: workingMessage(model.working))
    .alert("すべてのデータを削除しますか？", isPresented: $confirmsDelete) {
      Button("削除する", role: .destructive) {
        Task { if await model.deleteAllData() { onReset() } }
      }
      Button("キャンセル", role: .cancel) {}
    } message: {
      Text("面接の記録がすべて削除され、元に戻すことはできません。")
    }
    .alert("ログアウトしますか？", isPresented: $confirmsSignOut) {
      Button("ログアウト", role: .destructive) {
        Task { if await model.signOut() { onReset() } }
      }
      Button("キャンセル", role: .cancel) {}
    } message: {
      Text("もう一度Appleでログインすると、これまでの記録を見られます。")
    }
    .alert(failureTitle(model.failure), isPresented: failureBinding(model)) {
      Button("OK", role: .cancel) {}
    } message: {
      // Apple 쪽에서 실패한 로그인은 통신 문제가 아닐 수 있다
      if model.failure == .signIn {
        Text("しばらくしてから、もう一度お試しください。")
      } else {
        Text("通信状況を確認して、もう一度お試しください。")
      }
    }
  }

  private func section<Content: View>(
    _ number: Int, _ title: LocalizedStringKey, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 10) {
        Text(verbatim: String(format: "%02d", number))
          .font(.caption.monospacedDigit().weight(.bold))
          .foregroundStyle(TechPalette.accent)
        Text(title).font(.headline)
      }
      .padding(.horizontal, 4)
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.isHeader)
      VStack(spacing: 0, content: content)
        .background(TechCardBackground(showsBorder: false))
    }
  }

  @ViewBuilder
  private func accountCard(_ model: MenuModel) -> some View {
    MenuRow(icon: "person.badge.key.fill", title: "ログイン状態", showsChevron: false) {
      switch model.account {
      case .loading:
        DotScanSkeleton(spacing: 4, bandWidth: 30) {
          SkeletonBox(width: 80, height: 12, cornerRadius: 6)
        }
      case .failed: Text("確認できませんでした")
      case .loaded(.guest): Text("ゲスト")
      case .loaded(.apple): Text("Appleアカウント")
      }
    }
    VStack(alignment: .leading, spacing: 8) {
      switch model.account {
      case .loading:
        EmptyView()
      case .failed:
        OutlineButton(title: "再試行", icon: nil, tint: TechPalette.accent) {
          Task { await model.loadAccount() }
        }
      case .loaded(.guest):
        if BuildConfig.appleSignInEnabled {
          AppleSignInButton(height: 46) { request in
            Task { await model.signIn(request) }
          } onFailed: {
            model.reportSignInFailure()
          }
          Text("Appleでログインすると、別のiPhoneでも記録を見られます。")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      case .loaded(.apple):
        OutlineButton(title: "ログアウト", icon: nil, tint: TechPalette.negative) {
          confirmsSignOut = true
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, accountHasControls(model) ? 14 : 0)
  }

  private func accountHasControls(_ model: MenuModel) -> Bool {
    switch model.account {
    case .loading: false
    case .loaded(.guest): BuildConfig.appleSignInEnabled
    default: true
    }
  }

  private func workingMessage(_ action: MenuModel.Action?) -> LocalizedStringKey {
    switch action {
    case .signIn: "ログインしています…"
    case .signOut: "ログアウトしています…"
    case .delete, nil: "削除しています…"
    }
  }

  private func failureTitle(_ failure: MenuModel.Action?) -> LocalizedStringKey {
    switch failure {
    case .signIn: "ログインできませんでした"
    case .signOut: "ログアウトできませんでした"
    case .delete, nil: "削除できませんでした"
    }
  }

  private func failureBinding(_ model: MenuModel) -> Binding<Bool> {
    Binding(get: { model.failure != nil }, set: { if !$0 { model.failure = nil } })
  }
}

// 왼쪽 파란 아이콘, 제목, 오른쪽 값, 넘어가는 줄이면 화살표
private struct MenuRow<Value: View>: View {
  let icon: String
  let title: LocalizedStringKey
  var showsChevron = true
  @ViewBuilder var value: Value

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.white)
        .frame(width: 32, height: 32)
        .background(
          RoundedRectangle(cornerRadius: 9, style: .continuous).fill(
            LinearGradient(
              colors: [SplashPalette.top, SplashPalette.middle], startPoint: .topLeading,
              endPoint: .bottomTrailing))
        )
        .accessibilityHidden(true)
      Text(title)
      Spacer(minLength: 8)
      // 「確認できませんでした」처럼 긴 값도 잘리지 않게 조금 줄여서 한 줄에 넣는다
      value.foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.75)
      if showsChevron {
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
          .accessibilityHidden(true)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .contentShape(Rectangle())
  }
}

extension MenuRow where Value == EmptyView {
  init(icon: String, title: LocalizedStringKey, showsChevron: Bool = true) {
    self.init(icon: icon, title: title, showsChevron: showsChevron) { EmptyView() }
  }
}

private struct OutlineButton: View {
  let title: LocalizedStringKey
  let icon: String?
  let tint: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let icon { Image(systemName: icon).accessibilityHidden(true) }
        Text(title)
      }
      .font(.subheadline.weight(.semibold))
      .frame(maxWidth: .infinity, minHeight: 46)
      .overlay { Capsule().strokeBorder(tint.opacity(0.5), lineWidth: 1) }
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .foregroundStyle(tint)
  }
}

#Preview {
  MenuView()
}
