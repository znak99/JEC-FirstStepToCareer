import SwiftUI

struct InterviewSessionView: View {
  let context: InterviewSessionContext
  let onFinished: (String) -> Void
  let onQuit: () -> Void

  @Environment(\.apiClient) private var api
  @Environment(\.scenePhase) private var scenePhase
  @State private var model: InterviewSessionModel?
  @State private var confirmingQuit = false

  var body: some View {
    Group {
      if let model {
        content(model)
      } else {
        ProgressView()
      }
    }
    .navigationTitle("面接")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button("やめる", role: .destructive) {
          model?.pause()
          confirmingQuit = true
        }
      }
    }
    .confirmationDialog("面接をやめますか？", isPresented: $confirmingQuit, titleVisibility: .visible) {
      Button("やめる（記録を削除）", role: .destructive) {
        Task {
          await model?.quit()
          onQuit()
        }
      }
      Button("続ける", role: .cancel) {}
    } message: {
      Text("途中でやめた面接は保存されません。")
    }
    .task {
      if model == nil {
        let created = InterviewSessionModel(context: context, api: api)
        model = created
        await created.start()
      }
    }
    .onChange(of: model?.phase) { _, phase in
      if phase == .finished, let id = model?.interview.id { onFinished(id) }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active { model?.pause() }
    }
    .onDisappear { model?.tearDown() }
  }

  private func content(_ model: InterviewSessionModel) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      Text(model.questionNumberText)
        .font(.subheadline.bold())
        .foregroundStyle(.secondary)
      if let preface = model.question.preface {
        Text(preface)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      Text(model.question.text)
        .font(.title3.bold())
      Divider()
      phaseView(model)
      Spacer()
      controls(model)
    }
    .padding()
  }

  @ViewBuilder
  private func phaseView(_ model: InterviewSessionModel) -> some View {
    switch model.phase {
    case .speaking:
      Label("読み上げ中…", systemImage: "speaker.wave.2")
        .foregroundStyle(.secondary)
    case .listening:
      VStack(alignment: .leading, spacing: 8) {
        Label("お話しください", systemImage: "mic.fill")
          .foregroundStyle(.red)
        if let notice = model.notice {
          Text(notice).font(.footnote).foregroundStyle(.orange)
        }
        ScrollView {
          Text(model.transcript.isEmpty ? "（聞き取った内容がここに表示されます）" : model.transcript)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(model.transcript.isEmpty ? .secondary : .primary)
        }
        .frame(maxHeight: 240)
      }
    case .submitting:
      HStack {
        ProgressView()
        Text("次の質問を準備しています…")
      }
    case .closing:
      Label("面接を終えています…", systemImage: "speaker.wave.2")
        .foregroundStyle(.secondary)
    case .paused:
      VStack(alignment: .leading, spacing: 8) {
        Label("一時停止中", systemImage: "pause.circle")
          .foregroundStyle(.secondary)
        if !model.transcript.isEmpty {
          Text(model.transcript).frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    case .failed(let message):
      Label(message, systemImage: "exclamationmark.triangle")
        .foregroundStyle(.red)
    case .finished:
      ProgressView()
    }
  }

  @ViewBuilder
  private func controls(_ model: InterviewSessionModel) -> some View {
    VStack(spacing: 12) {
      switch model.phase {
      case .listening:
        Button {
          Task { await model.finishAnswer() }
        } label: {
          Text("回答を終える").frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
      case .paused:
        Button {
          Task { await model.resume() }
        } label: {
          Text("再開する").frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
      case .failed:
        Button {
          Task { await model.retry() }
        } label: {
          Text("再試行").frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
      default:
        EmptyView()
      }
      if model.canPause {
        Button {
          model.pause()
        } label: {
          Label("一時停止", systemImage: "pause").frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
      }
    }
  }
}
