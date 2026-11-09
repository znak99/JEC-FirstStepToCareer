import SwiftUI

// 온보딩 ②. 이름(닉네임, 필수)과 희망 조건(선택)을 받는다 (SITE_MAP S-15).
// 「はじめる」를 누르면 동의 기록과 프로필을 서버에 저장한다
struct ProfileSetupView: View {
  var onFinished: () -> Void = {}

  @Environment(\.apiClient) private var api
  @State private var draft = ProfileDraft()
  @State private var model: ProfileViewModel?

  var body: some View {
    NavigationStack {
      OnboardingScreen(
        step: 2, title: "あなたについて\n教えてください",
        message: "お名前（ニックネーム）だけで始められます。\nほかの項目は後からメニューで変更できます。",
        buttonTitle: "はじめる", canContinue: draft.profile != nil && model?.isSaving != true
      ) {
        finish()
      } content: {
        ProfileFormCard(draft: $draft)
      }
      .toolbar(.hidden, for: .navigationBar)
      .profileChoiceDestinations($draft)
      .loadingOverlay(model?.isSaving == true, message: "保存しています…")
      .saveFailedAlert(for: model)
    }
    .task { await prepare() }
  }

  // 같은 Apple 계정으로 다른 iPhone에서 입력해 둔 값이 있으면 미리 채운다
  private func prepare() async {
    guard model == nil else { return }
    let model = ProfileViewModel(api: api)
    self.model = model
    if let profile = await model.load(), draft == ProfileDraft() {
      draft = ProfileDraft(profile)
    }
  }

  private func finish() {
    guard let profile = draft.profile, let model else { return }
    Task {
      if await model.save(profile, agreeingTo: LegalDocument.allCases) { onFinished() }
    }
  }
}

#Preview {
  ProfileSetupView()
}
