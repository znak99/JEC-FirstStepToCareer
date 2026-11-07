import SwiftUI

// 메뉴 > プロフィール. 온보딩에서 입력한 이름과 희망 조건을 고친다 (SITE_MAP S-17)
struct ProfileEditView: View {
  @Environment(\.apiClient) private var api
  @Environment(\.dismiss) private var dismiss
  @State private var draft = ProfileDraft()
  @State private var model: ProfileModel?
  @State private var isLoaded = false

  var body: some View {
    ScrollView {
      if isLoaded {
        ProfileFormCard(draft: $draft)
          .padding(24)
      } else {
        ProgressView()
          .padding(.top, 80)
      }
    }
    .scrollDismissesKeyboard(.interactively)
    .background { OnboardingBackground() }
    .safeAreaInset(edge: .bottom) {
      Button("保存") { save() }
        .buttonStyle(OnboardingButtonStyle())
        .disabled(!isLoaded || draft.profile == nil || model?.isSaving == true)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
    .overlay {
      if model?.isSaving == true { ProgressView().controlSize(.large) }
    }
    .navigationTitle("プロフィール")
    .navigationBarTitleDisplayMode(.inline)
    .profileChoiceDestinations($draft)
    .alert("保存できませんでした", isPresented: saveFailed) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("しばらくしてから、もう一度お試しください。")
    }
    .task { await load() }
  }

  private var saveFailed: Binding<Bool> {
    Binding(get: { model?.saveFailed ?? false }, set: { model?.saveFailed = $0 })
  }

  private func load() async {
    guard model == nil else { return }
    let model = ProfileModel(api: api)
    self.model = model
    if let profile = await model.load() { draft = ProfileDraft(profile) }
    isLoaded = true
  }

  private func save() {
    guard let profile = draft.profile, let model else { return }
    Task {
      if await model.save(profile) { dismiss() }
    }
  }
}

#Preview {
  NavigationStack { ProfileEditView() }
}
