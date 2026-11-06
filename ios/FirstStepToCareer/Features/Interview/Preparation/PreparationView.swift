import SwiftUI

struct PreparationView: View {
  let draft: InterviewDraft
  let onStart: (InterviewSessionContext) -> Void

  @Environment(\.apiClient) private var api
  @State private var model: PreparationModel?
  @State private var started = false

  var body: some View {
    Group {
      if let model {
        content(model)
      } else {
        ProgressView()
      }
    }
    .navigationTitle("面接の準備")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
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

  @ViewBuilder
  private func content(_ model: PreparationModel) -> some View {
    if let tracker = model.tracker, showsCamera(model) {
      cameraLayout(model, tracker: tracker)
    } else {
      listLayout(model)
    }
  }

  // 얼굴 추적을 쓸 수 있으면 카메라를 화면 전체에 깔고, 점검 항목과 버튼은 아래 카드에 둔다
  private func cameraLayout(_ model: PreparationModel, tracker: FaceTracker) -> some View {
    ZStack {
      FaceCameraView(session: tracker.session)
        .ignoresSafeArea()
      VStack(spacing: 12) {
        GazeTargetView(tracker: tracker, baseline: model.baseline)
        Spacer()
        VStack(alignment: .leading, spacing: 12) {
          if model.requiredChecksPassed {
            Label("読み上げ・聞き取り・サーバーを確認しました", systemImage: "checkmark.circle.fill")
              .font(.footnote)
              .foregroundStyle(.green)
          } else {
            checkRows(model)
          }
          Divider()
          faceStatus(model)
          Text("スマートフォンを手に持って面接を受ける場合も、その姿勢のまま基準点を設定してください。")
            .font(.caption)
            .foregroundStyle(.secondary)
          if let error = model.startError {
            Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
          }
          startButton(model)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
      }
      .padding()
    }
    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
  }

  private func listLayout(_ model: PreparationModel) -> some View {
    List {
      Section("確認項目") { checkRows(model) }
      Section("視線・頭の動き") { faceStatus(model) }
      if let error = model.startError {
        Section { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
      }
    }
    .safeAreaInset(edge: .bottom) {
      startButton(model)
        .padding()
        .background(.bar)
    }
  }

  @ViewBuilder
  private func checkRows(_ model: PreparationModel) -> some View {
    CheckRow(title: "読み上げ（音声合成）", state: model.speech)
    CheckRow(title: "聞き取り（音声認識）", state: model.recognition)
    CheckRow(title: "サーバー・AI", state: model.server)
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
      Group {
        if model.isStarting {
          ProgressView()
        } else {
          Text("面接を始める")
        }
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
    .disabled(!model.canStart)
  }

  @ViewBuilder
  private func faceStatus(_ model: PreparationModel) -> some View {
    switch model.face {
    case .checking:
      HStack {
        ProgressView()
        Text("確認中…")
      }
    case .ready:
      Button("基準点を設定する（3秒間画面を見つめてください）") {
        Task { await model.calibrate() }
      }
    case .calibrating:
      HStack {
        ProgressView()
        Text("そのまま画面を見つめてください…")
      }
    case .calibrated:
      Label("基準点を設定しました", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
    case .skipped(let reason):
      VStack(alignment: .leading, spacing: 8) {
        Label("視線・頭の動きは評価されません", systemImage: "eye.slash")
        Text(reason).font(.footnote).foregroundStyle(.secondary)
        if model.isRetryableSkip {
          Button("もう一度基準点を設定する") { Task { await model.calibrate() } }
        }
      }
    }
  }

  private func showsCamera(_ model: PreparationModel) -> Bool {
    model.face != .checking && !isUnavailable(model.face)
  }

  private func isUnavailable(_ state: PreparationModel.FaceState) -> Bool {
    if case .skipped = state, model?.isRetryableSkip == false { return true }
    return false
  }
}

private struct CheckRow: View {
  let title: String
  let state: PreparationModel.CheckState

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(title)
        Spacer()
        switch state {
        case .checking: ProgressView()
        case .passed: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed: Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        }
      }
      if case .failed(let message) = state {
        Text(message).font(.footnote).foregroundStyle(.secondary)
      }
    }
  }
}
