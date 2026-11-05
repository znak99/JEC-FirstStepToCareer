import ARKit
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

  private func content(_ model: PreparationModel) -> some View {
    List {
      Section("確認項目") {
        CheckRow(title: "読み上げ（音声合成）", state: model.speech)
        CheckRow(title: "聞き取り（音声認識）", state: model.recognition)
        CheckRow(title: "サーバー・AI", state: model.server)
      }
      Section {
        faceSection(model)
      } header: {
        Text("視線・頭の動き")
      } footer: {
        if model.tracker != nil {
          Text("スマートフォンを手に持って面接を受ける場合も、その姿勢のまま基準点を設定してください。")
        }
      }
      if let error = model.startError {
        Section { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
      }
    }
    .safeAreaInset(edge: .bottom) {
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
      .padding()
      .background(.bar)
    }
  }

  @ViewBuilder
  private func faceSection(_ model: PreparationModel) -> some View {
    if let tracker = model.tracker, model.face != .checking, !isUnavailable(model.face) {
      CameraPreview(session: tracker.session)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .listRowInsets(EdgeInsets())
    }
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

private struct CameraPreview: UIViewRepresentable {
  let session: ARSession

  func makeUIView(context: Context) -> ARSCNView {
    let view = ARSCNView()
    view.session = session
    view.automaticallyUpdatesLighting = false
    return view
  }

  func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
