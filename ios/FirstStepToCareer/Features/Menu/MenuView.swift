import SwiftUI

enum MenuRoute: Hashable {
  case profile
  case terms
  case privacy
  case appInfo
}

struct MenuView: View {
  // 로그아웃·데이터 삭제가 끝났을 때 부른다. 온보딩부터 다시 한다
  var onReset: () -> Void = {}

  @Environment(\.apiClient) private var api
  @State private var model: MenuModel?
  @State private var confirmsDelete = false
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
    @Bindable var model = model
    return List {
      Section("プロフィール") {
        NavigationLink(value: MenuRoute.profile) {
          LabeledContent("お名前（ニックネーム）") {
            if let nickname { Text(nickname) } else { Text("未設定") }
          }
        }
      }

      accountSection(model)

      Section("情報") {
        NavigationLink("利用規約", value: MenuRoute.terms)
        NavigationLink("プライバシーポリシー", value: MenuRoute.privacy)
        NavigationLink("アプリ情報", value: MenuRoute.appInfo)
      }

      Section {
        Button("すべてのデータを削除", role: .destructive) { confirmsDelete = true }
      } footer: {
        Text("サーバーに保存された面接の記録をすべて削除します。元に戻すことはできません。")
      }
    }
    .disabled(model.isWorking)
    .overlay {
      if model.isWorking { ProgressView().controlSize(.large) }
    }
    .alert(
      "すべてのデータを削除しますか？", isPresented: $confirmsDelete
    ) {
      Button("削除する", role: .destructive) {
        Task { if await model.deleteAllData() { onReset() } }
      }
      Button("キャンセル", role: .cancel) {}
    } message: {
      Text("面接の記録がすべて削除され、元に戻すことはできません。")
    }
    .alert(
      failureTitle(model.failure), isPresented: failureBinding(model)
    ) {
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

  @ViewBuilder
  private func accountSection(_ model: MenuModel) -> some View {
    Section {
      switch model.account {
      case .loading:
        LabeledContent("ログイン状態") { ProgressView() }
      case .failed:
        LabeledContent("ログイン状態", value: String(localized: "確認できませんでした"))
        Button("再試行") { Task { await model.loadAccount() } }
      case .loaded(.guest):
        LabeledContent("ログイン状態", value: String(localized: "ゲスト"))
        if BuildConfig.appleSignInEnabled {
          AppleSignInButton { request in
            Task { await model.signIn(request) }
          } onFailed: {
            model.reportSignInFailure()
          }
          .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
      case .loaded(.apple):
        LabeledContent("ログイン状態", value: String(localized: "Appleアカウント"))
        Button("ログアウト") {
          Task { if await model.signOut() { onReset() } }
        }
      }
    } header: {
      Text("アカウント")
    } footer: {
      if model.account == .loaded(.guest) && BuildConfig.appleSignInEnabled {
        Text("Appleでログインすると、別のiPhoneでも記録を見られます。")
      }
    }
  }

  private func failureTitle(_ failure: MenuModel.Failure?) -> LocalizedStringKey {
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

#Preview {
  MenuView()
}
