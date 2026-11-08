import SwiftUI

// 면접관, 오른쪽 위 작은 내 화면, 질문 카드, 답변 카드, 아래 버튼 (SITE_MAP S-04, 시안 B)
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
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background { OnboardingBackground() }
    .navigationTitle("面接")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button {
          model?.pause()
          confirmingQuit = true
        } label: {
          Text("やめる").foregroundStyle(TechPalette.negative)
        }
      }
    }
    .alert("面接をやめますか？", isPresented: $confirmingQuit) {
      Button("続ける", role: .cancel) {}
      Button("やめる", role: .destructive) {
        Task {
          await model?.quit()
          onQuit()
        }
      }
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
    VStack(spacing: 16) {
      QuestionProgress(position: model.question.position, total: model.interview.questionCount)
      InterviewerAvatar(isSpeaking: model.phase == .speaking || model.phase == .closing)
      questionCard(model)
      Spacer(minLength: 0)
      answerCard(model)
        // 받아쓴 글이 길어지면 남은 자리를 먼저 차지하고, 넘치면 카드 안에서 스크롤한다
        .layoutPriority(1)
      controls(model)
    }
    .overlay(alignment: .topTrailing) {
      SelfView(tracker: context.tracker, frontCamera: context.frontCamera)
        .padding(.top, 36)
    }
    .padding(.horizontal, 20)
    .padding(.bottom, 8)
  }

  private func questionCard(_ model: InterviewSessionModel) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      if let preface = model.question.preface {
        Text(preface)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      Text(model.question.text)
        .font(.title3.bold())
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(TechCardBackground(showsBorder: false))
    .fixedSize(horizontal: false, vertical: true)
  }

  // MARK: 답변 카드

  private func answerCard(_ model: InterviewSessionModel) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      if let badge = PhaseBadge(phase: model.phase) {
        HStack {
          badge
          Spacer()
          if model.phase == .listening { LevelBars(model: model) }
        }
      }
      answerBody(model)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(TechCardBackground(showsBorder: false))
  }

  @ViewBuilder
  private func answerBody(_ model: InterviewSessionModel) -> some View {
    switch model.phase {
    case .speaking:
      Text("読み上げが終わると、回答の聞き取りを始めます")
        .font(.footnote)
        .foregroundStyle(.secondary)
    case .listening:
      if let notice = model.notice {
        Text(notice).font(.footnote).foregroundStyle(.orange)
      }
      TranscriptView(text: model.transcript)
    case .submitting:
      HStack(spacing: 8) {
        ProgressView()
        Text("次の質問を準備しています…")
      }
      .font(.subheadline)
    case .closing:
      Text("面接を終えています…")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    case .paused:
      if !model.transcript.isEmpty {
        TranscriptView(text: model.transcript)
      }
    case .failed(let message):
      Label(message, systemImage: "exclamationmark.triangle")
        .font(.subheadline)
        .foregroundStyle(TechPalette.negative)
    case .finished:
      ProgressView()
    }
  }

  // MARK: 아래 버튼

  @ViewBuilder
  private func controls(_ model: InterviewSessionModel) -> some View {
    switch model.phase {
    case .speaking:
      PauseButton(fillsWidth: true) { model.pause() }
    case .listening:
      HStack(spacing: 10) {
        PauseButton(fillsWidth: false) { model.pause() }
          .fixedSize(horizontal: true, vertical: false)
        Button("回答を終える") {
          Task { await model.finishAnswer() }
        }
        .buttonStyle(OnboardingButtonStyle())
      }
    case .paused:
      Button("再開する") {
        Task { await model.resume() }
      }
      .buttonStyle(OnboardingButtonStyle())
    case .failed:
      Button("再試行") {
        Task { await model.retry() }
      }
      .buttonStyle(OnboardingButtonStyle())
    default:
      EmptyView()
    }
  }
}

// 「質問 1 / 5」와 질문 수만큼 나눈 막대. 지난 질문과 지금 질문 칸을 채운다
private struct QuestionProgress: View {
  let position: Int
  let total: Int

  var body: some View {
    HStack(spacing: 10) {
      Text("質問 \(position) / \(total)")
        .font(.caption.weight(.semibold))
        .monospacedDigit()
      HStack(spacing: 4) {
        ForEach(1...max(total, 1), id: \.self) { index in
          Capsule()
            .fill(
              index <= position ? AnyShapeStyle(TechPalette.accent) : AnyShapeStyle(.quaternary)
            )
            .frame(height: 4)
        }
      }
      .accessibilityHidden(true)
    }
  }
}

// 질문을 읽는 동안 둘레에 고리가 천천히 퍼진다. '동작 줄이기'가 켜져 있으면 멈춘 고리를 보여 준다
private struct InterviewerAvatar: View {
  let isSpeaking: Bool

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private let size: CGFloat = 104
  private let spread: CGFloat = 1.45

  var body: some View {
    VStack(spacing: 8) {
      ZStack {
        if isSpeaking { rings }
        Circle()
          .fill(
            LinearGradient(
              colors: [SplashPalette.top, SplashPalette.bottom], startPoint: .topLeading,
              endPoint: .bottomTrailing)
          )
          .frame(width: size, height: size)
          .shadow(color: SplashPalette.middle.opacity(0.35), radius: 13)
        Image(systemName: "person.fill")
          .font(.system(size: size * 0.45))
          .foregroundStyle(.white)
      }
      .frame(width: size * spread, height: size * spread)
      Text("面接官")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("面接官"))
  }

  @ViewBuilder
  private var rings: some View {
    if reduceMotion {
      ring(progress: 0.4)
      ring(progress: 0.9)
    } else {
      TimelineView(.animation) { timeline in
        let seconds = timeline.date.timeIntervalSinceReferenceDate
        ZStack {
          ForEach(0..<2, id: \.self) { index in
            ring(progress: (seconds / 1.8 + Double(index) / 2).truncatingRemainder(dividingBy: 1))
          }
        }
      }
    }
  }

  // progress 0이면 아이콘 가장자리, 1이면 가장 바깥에서 사라진다
  private func ring(progress: Double) -> some View {
    let diameter = size * (1 + (spread - 1) * progress)
    return Circle()
      .stroke(TechPalette.accent.opacity(0.35 * (1 - progress)), lineWidth: 6)
      .frame(width: diameter, height: diameter)
  }
}

// 오른쪽 위 작은 내 화면. 카메라를 쓸 수 없으면 보이지 않는다.
// 영상은 화면에 보여 주기만 하고 저장하거나 보내지 않는다
private struct SelfView: View {
  let tracker: FaceTracker?
  let frontCamera: FrontCamera?

  var body: some View {
    if tracker != nil || frontCamera != nil {
      let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
      Group {
        if let tracker {
          FaceCameraView(session: tracker.session, showsFaceOverlay: false)
        } else if let frontCamera {
          FrontCameraView(session: frontCamera.session)
        }
      }
      .frame(width: 84, height: 112)
      .clipShape(shape)
      .overlay { shape.strokeBorder(.white.opacity(0.35), lineWidth: 1) }
      .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
      .accessibilityHidden(true)
    }
  }
}

private struct PhaseBadge: View {
  let icon: String
  let title: LocalizedStringKey
  let color: Color

  // 상태 표시가 없는 단계는 nil
  init?(phase: InterviewSessionModel.Phase) {
    switch phase {
    case .speaking, .closing:
      (icon, title, color) = ("speaker.wave.2.fill", "読み上げ中", TechPalette.accent)
    case .listening:
      (icon, title, color) = ("mic.fill", "お話しください", TechPalette.negative)
    case .paused:
      (icon, title, color) = ("pause.fill", "一時停止中", .secondary)
    case .submitting, .failed, .finished:
      return nil
    }
  }

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: icon).accessibilityHidden(true)
      Text(title)
    }
    .font(.caption.weight(.bold))
    .foregroundStyle(color)
    .padding(.horizontal, 10)
    .frame(minHeight: 26)
    .background(Capsule().fill(color.opacity(0.14)))
  }
}

// 마이크 소리 크기에 맞춰 움직이는 막대. 이 뷰만 다시 그리도록 모델에서 직접 읽는다
private struct LevelBars: View {
  let model: InterviewSessionModel

  private static let shape: [CGFloat] = [
    0.35, 0.6, 0.9, 0.7, 1, 0.5, 0.8, 0.4, 0.75, 0.95, 0.6, 0.3,
  ]

  var body: some View {
    let level = CGFloat(model.level)
    HStack(spacing: 3) {
      ForEach(Self.shape.indices, id: \.self) { index in
        Capsule()
          .fill(TechPalette.negative)
          .frame(width: 3, height: 4 + 20 * level * Self.shape[index])
      }
    }
    .frame(height: 24)
    .animation(.easeOut(duration: 0.12), value: level)
    .accessibilityHidden(true)
  }
}

// 받아쓴 글. 내용만큼 커지다가 자리가 모자라면 스크롤하며 늘 마지막 줄을 보여 준다
private struct TranscriptView: View {
  let text: String

  @State private var contentHeight: CGFloat = 0

  var body: some View {
    ScrollView {
      Group {
        if text.isEmpty {
          Text("（聞き取った内容がここに表示されます）").foregroundStyle(.secondary)
        } else {
          Text(text)
        }
      }
      .font(.subheadline)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .defaultScrollAnchor(.bottom)
    .onScrollGeometryChange(for: CGFloat.self) {
      $0.contentSize.height
    } action: { _, height in
      contentHeight = height
    }
    .frame(maxHeight: max(contentHeight, 20))
  }
}

private struct PauseButton: View {
  let fillsWidth: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Label("一時停止", systemImage: "pause.fill")
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
        .padding(.horizontal, 22)
        .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: 50)
        .overlay { Capsule().strokeBorder(TechPalette.accent.opacity(0.6), lineWidth: 1) }
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .foregroundStyle(TechPalette.accent)
  }
}
