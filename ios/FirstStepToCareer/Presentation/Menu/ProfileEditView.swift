import SwiftUI

// 메뉴 > プロフィール. 온보딩에서 입력한 이름과 희망 조건을 고친다 (SITE_MAP S-17)
struct ProfileEditView: View {
  @Environment(\.apiClient) private var api
  @Environment(\.dismiss) private var dismiss
  @State private var draft = ProfileDraft()
  @State private var model: ProfileViewModel?
  @State private var isLoaded = false

  var body: some View {
    ScrollView {
      if isLoaded {
        ProfileFormCard(draft: $draft)
          .padding(24)
      } else {
        ProfileFormSkeleton()
          .padding(24)
      }
    }
    .scrollDisabled(!isLoaded)
    .scrollDismissesKeyboard(.interactively)
    .background { TechPageBackground() }
    .safeAreaInset(edge: .bottom) {
      Button("保存") { save() }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!isLoaded || draft.profile == nil || model?.isSaving == true)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
    .loadingOverlay(model?.isSaving == true, message: "保存しています…")
    .reservesTabBarSpace()
    .navigationTitle("プロフィール")
    .navigationBarTitleDisplayMode(.inline)
    .profileChoiceDestinations($draft)
    .saveFailedAlert(for: model)
    .task { await load() }
  }

  private func load() async {
    guard model == nil else { return }
    let model = ProfileViewModel(api: api)
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

// 프로필을 불러오는 동안 입력 카드의 칸 자리에 빈 상자를 둔다
private struct ProfileFormSkeleton: View {
  var body: some View {
    DotScanSkeleton {
      VStack(alignment: .leading, spacing: 18) {
        VStack(alignment: .leading, spacing: 8) {
          SkeletonBox(width: 150, height: 14)
          SkeletonBox(height: 46, cornerRadius: 12)
          SkeletonBox(width: 200, height: 11)
        }
        VStack(alignment: .leading, spacing: 8) {
          SkeletonBox(width: 90, height: 14)
          HStack(spacing: 10) {
            SkeletonBox(height: 40, cornerRadius: 20)
            SkeletonBox(height: 40, cornerRadius: 20)
          }
        }
        ForEach(0..<2, id: \.self) { _ in
          VStack(alignment: .leading, spacing: 8) {
            SkeletonBox(width: 60, height: 14)
            SkeletonBox(height: 46, cornerRadius: 12)
          }
        }
      }
      .padding(18)
    }
  }
}

#Preview {
  NavigationStack { ProfileEditView() }
}
