import SwiftUI

// 온보딩 두 화면의 공통 틀. 시작 화면과 같은 밝은 테크 느낌이다 (SITE_MAP S-14·S-15)
struct OnboardingScreen<Content: View>: View {
  let step: Int
  let title: LocalizedStringKey
  let message: LocalizedStringKey
  let buttonTitle: LocalizedStringKey
  let canContinue: Bool
  let onContinue: () -> Void
  @ViewBuilder var content: Content

  static var stepCount: Int { 2 }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header
        VStack(alignment: .leading, spacing: 8) {
          Text(title).font(.title.bold())
          Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        content
      }
      .padding(.horizontal, 24)
      .padding(.top, 16)
      .padding(.bottom, 24)
    }
    .scrollBounceBehavior(.basedOnSize)
    .scrollDismissesKeyboard(.interactively)
    .safeAreaInset(edge: .bottom) {
      Button(action: onContinue) {
        Text(buttonTitle)
      }
      .buttonStyle(OnboardingButtonStyle())
      .disabled(!canContinue)
      .padding(.horizontal, 24)
      .padding(.bottom, 12)
    }
    .background {
      LinearGradient(
        colors: [TechPalette.cardTop, TechPalette.cardBottom], startPoint: .top, endPoint: .bottom
      )
      .overlay { DotGrid() }
      .ignoresSafeArea()
    }
  }

  private var header: some View {
    HStack(spacing: 10) {
      Image("AppLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityHidden(true)
      Text("就活一歩").font(.headline)
      Spacer()
      Text(verbatim: "\(step) / \(Self.stepCount)")
        .font(.caption.monospacedDigit().weight(.semibold))
        .foregroundStyle(TechPalette.accent)
        .accessibilityHidden(true)
    }
  }
}

struct OnboardingButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, minHeight: 50)
      // 밝은/어두운 모드 모두 앱 아이콘과 같은 파랑 그라데이션
      .background(
        Capsule().fill(
          LinearGradient(
            colors: [SplashPalette.top, SplashPalette.bottom], startPoint: .topLeading,
            endPoint: .bottomTrailing))
      )
      .shadow(color: SplashPalette.middle.opacity(isEnabled ? 0.45 : 0), radius: 10)
      .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
      .contentShape(Capsule())
  }
}

struct OnboardingCheck: View {
  let isOn: Bool

  var body: some View {
    ZStack {
      Circle()
        .strokeBorder(isOn ? TechPalette.accent : Color.secondary.opacity(0.6), lineWidth: 1.5)
        .background(Circle().fill(isOn ? TechPalette.accent : .clear))
      if isOn {
        Image(systemName: "checkmark")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(TechPalette.cardTop)
      }
    }
    .frame(width: 26, height: 26)
    .accessibilityHidden(true)
  }
}

struct OnboardingFieldLabel: View {
  let title: LocalizedStringKey
  let isRequired: Bool

  var body: some View {
    HStack(spacing: 6) {
      Text(title).font(.subheadline.weight(.semibold))
      Group {
        if isRequired { Text("必須") } else { Text("任意") }
      }
      .font(.caption2.weight(.bold))
      .foregroundStyle(isRequired ? TechPalette.cardBottom : .secondary)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(Capsule().fill(isRequired ? TechPalette.accent : TechPalette.cardTop))
    }
  }
}

extension View {
  // 입력 칸과 선택 칸의 공통 모양
  func onboardingField() -> some View {
    let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
    return padding(.horizontal, 14)
      .frame(minHeight: 46)
      .background(shape.fill(TechPalette.cardTop))
      .overlay { shape.strokeBorder(TechPalette.accent.opacity(0.3), lineWidth: 1) }
  }
}
