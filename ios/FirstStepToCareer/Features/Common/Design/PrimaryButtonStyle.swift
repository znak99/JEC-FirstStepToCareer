import SwiftUI

// 화면 아래의 큰 버튼. 앱 아이콘의 파랑으로 채운 캡슐 모양이다
struct PrimaryButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, minHeight: 50)
      // 밝은/어두운 모드 모두 앱 아이콘의 파랑. 색 차이가 크지 않게 가운데 색까지만 쓴다
      .background(
        Capsule().fill(
          LinearGradient(
            colors: [BrandPalette.top, BrandPalette.middle], startPoint: .topLeading,
            endPoint: .bottomTrailing))
      )
      .shadow(color: BrandPalette.middle.opacity(isEnabled ? 0.45 : 0), radius: 10)
      .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
      .contentShape(Capsule())
  }
}
