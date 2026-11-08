import SwiftUI

// 카메라를 화면 전체에 깔고, 점검 결과·기준점·시작 버튼은 아래 카드에 둔다 (SITE_MAP S-03)
struct PreparationView: View {
  let draft: InterviewDraft
  let onStart: (InterviewSessionContext) -> Void

  @Environment(\.apiClient) private var api
  @Environment(\.openURL) private var openURL
  @State private var model: PreparationModel?
  @State private var started = false

  var body: some View {
    ZStack {
      cameraLayer.ignoresSafeArea()
      if let model { overlay(model) }
    }
    .navigationTitle("面接の準備")
    .navigationBarTitleDisplayMode(.inline)
    // 카메라 영상 위라 제목과 뒤로 가기는 밝은/어두운 모드 모두 흰색으로 둔다
    .toolbarColorScheme(.dark, for: .navigationBar)
    .hidesTabBar()
    .task {
      if model == nil {
        let created = PreparationModel(draft: draft, api: api)
        model = created
        await created.runChecks()
      }
    }
    .onDisappear {
      if !started { model?.leave() }
    }
  }

  // 영상은 화면에 보여 주기만 하고 저장하거나 보내지 않는다
  @ViewBuilder
  private var cameraLayer: some View {
    if let model, model.camera == .faceTracking, let tracker = model.tracker {
      FaceCameraView(session: tracker.session)
    } else if let model, model.camera == .mirror, let frontCamera = model.frontCamera {
      FrontCameraView(session: frontCamera.session)
    } else {
      CameraBackdrop()
    }
  }

  private func overlay(_ model: PreparationModel) -> some View {
    VStack(spacing: 12) {
      switch model.camera {
      case .faceTracking:
        if let tracker = model.tracker {
          GazeTargetView(tracker: tracker, baseline: model.baseline)
            .environment(\.colorScheme, .dark)
        }
        Spacer()
      case .denied:
        Spacer()
        CameraNotice(
          title: "カメラが許可されていません",
          detail: "自分の姿を確認するには、設定でカメラを許可してください。カメラなしでも面接はできます。"
        ) {
          if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
        }
        Spacer()
      case .unavailable:
        Spacer()
        CameraNotice(title: "カメラを利用できません", detail: "カメラなしでも面接はできます。", onOpenSettings: nil)
        Spacer()
      case .mirror, nil:
        Spacer()
      }
      card(model)
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 8)
  }

  // MARK: 아래 카드

  private func card(_ model: PreparationModel) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 8) {
        CheckChip(title: "読み上げ", state: model.speech)
        CheckChip(title: "聞き取り", state: model.recognition, blinkDelay: 0.3)
        CheckChip(title: "AI接続", state: model.server, blinkDelay: 0.6)
      }
      if !model.failureMessages.isEmpty {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(model.failureMessages, id: \.self) { message in
            Text(message)
          }
          .font(.footnote)
          .foregroundStyle(TechPalette.negative)
          Button("もう一度確認する") { Task { await model.recheck() } }
            .font(.subheadline.weight(.semibold))
            .tint(TechPalette.accent)
        }
      }
      Divider()
      faceRow(model)
      if model.camera == .faceTracking {
        Text("スマートフォンを手に持って面接を受ける場合も、その姿勢のまま基準点を設定してください。")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      if let error = model.startError {
        Label(error, systemImage: "exclamationmark.triangle")
          .font(.footnote)
          .foregroundStyle(TechPalette.negative)
      }
      startButton(model)
    }
    .padding(18)
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay {
          RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(TechPalette.cardTop.opacity(0.88))
        }
    )
  }

  private func faceRow(_ model: PreparationModel) -> some View {
    HStack(spacing: 12) {
      faceIcon(model)
        .font(.title3)
        .frame(width: 28)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        switch model.face {
        case .checking:
          Text("カメラを確認しています").font(.subheadline.weight(.semibold))
        case .ready:
          Text("基準点を設定してください").font(.subheadline.weight(.semibold))
          Text("3秒間、画面を見つめます").font(.caption).foregroundStyle(.secondary)
        case .calibrating:
          Text("そのまま画面を見つめてください…").font(.subheadline.weight(.semibold))
        case .calibrated:
          Text("基準点を設定しました").font(.subheadline.weight(.semibold))
          Text("視線と頭の動きを評価します").font(.caption).foregroundStyle(.secondary)
        case .skipped(let reason):
          Text("視線・頭の動きは評価されません").font(.subheadline.weight(.semibold))
          Text(reason).font(.caption).foregroundStyle(.secondary)
        }
      }
      .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
      if model.canCalibrate {
        Button {
          Task { await model.calibrate() }
        } label: {
          Group {
            if model.face == .ready { Text("設定する") } else { Text("やり直す") }
          }
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(TechPalette.accent)
          .padding(.horizontal, 14)
          .frame(minHeight: 34)
          .overlay { Capsule().strokeBorder(TechPalette.accent.opacity(0.6), lineWidth: 1) }
          .contentShape(Capsule())
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  private func faceIcon(_ model: PreparationModel) -> some View {
    switch model.face {
    case .checking:
      Image(systemName: "scope").foregroundStyle(TechPalette.accent).loadingBlink()
    case .calibrating:
      CountdownRing(duration: PreparationModel.calibrationSeconds).frame(width: 22, height: 22)
    case .ready:
      Image(systemName: "scope").foregroundStyle(TechPalette.accent)
    case .calibrated:
      Image(systemName: "checkmark.circle.fill").foregroundStyle(TechPalette.positive)
    case .skipped:
      Image(systemName: "eye.slash").foregroundStyle(.secondary)
    }
  }

  private func startButton(_ model: PreparationModel) -> some View {
    Button {
      Task {
        if let context = await model.start() {
          started = true
          onStart(context)
        }
      }
    } label: {
      if model.isStarting {
        LoadingDots(color: .white)
      } else {
        Text("面接を始める")
      }
    }
    .buttonStyle(OnboardingButtonStyle())
    .disabled(!model.canStart)
  }
}

private struct CheckChip: View {
  let title: LocalizedStringKey
  let state: PreparationModel.CheckState
  // 확인 중인 칩들이 차례로 깜박이게 한다
  var blinkDelay = 0.0

  var body: some View {
    HStack(spacing: 4) {
      switch state {
      case .checking:
        Circle()
          .fill(TechPalette.accent)
          .frame(width: 8, height: 8)
          .frame(width: 12, height: 12)
          .loadingBlink(delay: blinkDelay)
      case .passed:
        Image(systemName: "checkmark.circle.fill").foregroundStyle(TechPalette.positive)
      case .failed:
        Image(systemName: "xmark.circle.fill").foregroundStyle(TechPalette.negative)
      }
      Text(title)
    }
    .font(.caption.weight(.semibold))
    .lineLimit(1)
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity, minHeight: 32)
    .background(Capsule().fill(TechPalette.cardTop))
    .overlay { Capsule().strokeBorder(borderColor.opacity(0.4), lineWidth: 1) }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(title))
    .accessibilityValue(stateText)
  }

  private var borderColor: Color {
    switch state {
    case .checking: TechPalette.accent
    case .passed: TechPalette.positive
    case .failed: TechPalette.negative
    }
  }

  private var stateText: Text {
    switch state {
    case .checking: Text("確認中")
    case .passed: Text("確認済み")
    case .failed: Text("利用できません")
    }
  }
}

// 카메라 영상이 없을 때 카메라 자리를 채운다
private struct CameraBackdrop: View {
  var body: some View {
    LinearGradient(
      colors: [
        Color(red: 0.16, green: 0.19, blue: 0.24),
        Color(red: 0.05, green: 0.06, blue: 0.09),
      ],
      startPoint: .top, endPoint: .bottom)
  }
}

// 카메라를 쓸 수 없을 때 카메라 자리에 보여 주는 안내
private struct CameraNotice: View {
  let title: LocalizedStringKey
  let detail: LocalizedStringKey
  let onOpenSettings: (() -> Void)?

  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: "video.slash")
        .font(.system(size: 40, weight: .light))
        .accessibilityHidden(true)
      Text(title).font(.headline)
      Text(detail)
        .font(.footnote)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
      if let onOpenSettings {
        Button(action: onOpenSettings) {
          Text("設定を開く")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 18)
            .frame(minHeight: 36)
            .overlay { Capsule().strokeBorder(TechPalette.accent, lineWidth: 1) }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(TechPalette.accent)
        .padding(.top, 4)
      }
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 32)
    .environment(\.colorScheme, .dark)
  }
}
