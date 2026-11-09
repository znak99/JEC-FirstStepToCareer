import SwiftUI

// 가운데 앱 아이콘·이름·버전, 아래쪽 공개 저장소 버튼 (SITE_MAP S-11, 시안 B)
struct AppInfoView: View {
  private static let repositoryURL = URL(string: "https://github.com/znak99/JEC-FirstStepToCareer")!

  var body: some View {
    VStack(spacing: 14) {
      Spacer()
      Image("AppLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 112, height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: BrandPalette.middle.opacity(0.45), radius: 24)
        .accessibilityHidden(true)
      Text("就活一歩")
        .font(.title.weight(.bold))
        .accessibilityAddTraits(.isHeader)
      Text("バージョン \(BuildConfig.appVersion)")
        .font(.caption.monospacedDigit().weight(.semibold))
        .foregroundStyle(TechPalette.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(TechPalette.accent.opacity(0.1)))
      Spacer()
      Text("このアプリのソースコードは公開されています。")
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Link(destination: Self.repositoryURL) {
        HStack(spacing: 8) {
          Image(systemName: "chevron.left.forwardslash.chevron.right")
            .accessibilityHidden(true)
          Text("GitHubでソースコードを見る")
          Image(systemName: "arrow.up.right")
            .font(.caption.weight(.bold))
            .accessibilityHidden(true)
        }
      }
      .buttonStyle(PrimaryButtonStyle())
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background { TechPageBackground() }
    .reservesTabBarSpace()
    .navigationTitle("アプリ情報")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack { AppInfoView() }
}
