import SwiftUI

// 면접 탭의 첫 화면. 응모처와 면접 조건을 입력하고 바로 면접 준비로 간다 (SITE_MAP S-01)
struct InterviewHomeView: View {
  @Environment(\.apiClient) private var api
  @Environment(\.tabRootRequest) private var tabRootRequest
  @State private var path: [InterviewRoute] = []
  @State private var availability = Availability.loading
  @State private var form = InterviewForm(
    profile: ProfileStore().profile, questionCount: AppSettings.questionCount())

  enum Availability: Equatable {
    case loading
    case available
    case aiDisabled
    case failed
  }

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          statusCard
          section(1, "応募先") { applicationCard }
          section(2, "面接の条件") { conditions }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
      }
      .scrollDismissesKeyboard(.interactively)
      .scanRefreshable {
        await refresh()
        return availability != .failed
      }
      .safeAreaInset(edge: .bottom) {
        Button("面接を始める") { path.append(.preparation(form.draft)) }
          .buttonStyle(OnboardingButtonStyle())
          .disabled(availability != .available || !form.draft.isValid)
          .padding(.horizontal, 24)
          .padding(.bottom, 12)
      }
      .background { OnboardingBackground() }
      .reservesTabBarSpace()
      .navigationTitle("面接")
      .navigationDestination(for: InterviewRoute.self) { route in
        switch route {
        case .preparation(let draft):
          // 준비 화면은 경로에서 빼, 같은 카메라 영상을 두 화면이 함께 그리지 않게 한다
          PreparationView(draft: draft) { context in path = [.session(context)] }
        case .session(let context):
          InterviewSessionView(
            context: context,
            onFinished: { id in path = [.result(id)] },
            onQuit: { path = [] })
        case .result(let id):
          InterviewResultView(interviewId: id) { path = [] }
        case .choice(.industry):
          ChoiceListView(
            title: "業界", otherPlaceholder: "業界を入力", categories: ChoiceCatalog.industries,
            other: ProfileDraft.other, allowsNone: false, choice: $form.industryChoice,
            otherText: $form.otherIndustry)
        case .choice(.jobTitle):
          ChoiceListView(
            title: "職種", otherPlaceholder: "職種を入力", categories: ChoiceCatalog.jobTitles,
            other: ProfileDraft.other, allowsNone: false, choice: $form.jobChoice,
            otherText: $form.otherJob)
        }
      }
      .onChange(of: tabRootRequest) { path = [] }
      // 메뉴에서 프로필을 바꾸고 돌아왔을 때 반영한다
      .onAppear { form.sync(profile: ProfileStore().profile) }
      // 마지막으로 고른 질문 수로 다음에도 시작한다
      .onChange(of: form.questionCount) { _, count in AppSettings.setQuestionCount(count) }
      .task { await refresh() }
    }
  }

  // MARK: AI 상태

  private var statusCard: some View {
    HStack(spacing: 14) {
      ZStack {
        Circle().fill(statusColor.opacity(0.18)).frame(width: 44, height: 44)
        if availability == .loading {
          PulseDot()
        } else {
          Circle().fill(statusColor).frame(width: 12, height: 12)
            .shadow(color: statusColor, radius: 6)
        }
      }
      .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 4) {
        switch availability {
        case .loading:
          Text("AIの状態を確認しています").font(.headline)
        case .available:
          Text("AI面接官の準備ができています").font(.headline)
          Text("\(form.interviewType.label)・\(form.hiringType.label)・\(form.questionCount)問")
            .font(.caption)
            .foregroundStyle(.secondary)
        case .aiDisabled:
          Text("現在、AI機能は停止中です").font(.headline)
          Text("過去の記録は「記録」タブで見られます")
            .font(.caption)
            .foregroundStyle(.secondary)
        case .failed:
          Text("サーバーに接続できませんでした").font(.headline)
          Button("再試行") {
            availability = .loading
            Task { await refresh() }
          }
          .font(.caption.weight(.semibold))
          .tint(TechPalette.accent)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(16)
    .background(TechCardBackground())
  }

  private var statusColor: Color {
    switch availability {
    case .loading: TechPalette.accent
    case .available: TechPalette.positive
    case .aiDisabled: Color.secondary
    case .failed: TechPalette.negative
    }
  }

  // 탭을 오갈 때마다 다시 확인한다. 확인하는 동안에는 이전 상태를 그대로 보여 준다
  private func refresh() async {
    do {
      availability = try await api.status().aiEnabled ? .available : .aiDisabled
    } catch {
      // 탭을 옮겨 확인이 취소된 것은 연결 실패가 아니다
      if Task.isCancelled { return }
      availability = .failed
    }
  }

  // MARK: 입력

  private func section<Content: View>(
    _ number: Int, _ title: LocalizedStringKey, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 10) {
        Text(verbatim: String(format: "%02d", number))
          .font(.caption.monospacedDigit().weight(.bold))
          .foregroundStyle(TechPalette.accent)
        Text(title).font(.headline)
      }
      .padding(.horizontal, 4)
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.isHeader)
      content()
    }
  }

  private var applicationCard: some View {
    VStack(spacing: 0) {
      HStack {
        Text("会社名")
        Spacer()
        // 비워 두면 이 이름으로 면접한다 (InterviewForm.defaultCompanyName)
        TextField("株式会社就活一歩", text: $form.companyName)
          .multilineTextAlignment(.trailing)
          .submitLabel(.done)
          .accessibilityLabel(Text("会社名"))
      }
      .frame(minHeight: 48)
      Divider()
      // 업계·직종은 앱 어디서나 새 화면에서 고른다 (SITE_MAP 4절). 탭을 다시 누르면 닫히게 경로에 넣는다
      NavigationLink(value: InterviewRoute.choice(.industry)) {
        choiceRow("業界", choice: form.industryChoice, otherText: form.otherIndustry)
      }
      .buttonStyle(.plain)
      Divider()
      NavigationLink(value: InterviewRoute.choice(.jobTitle)) {
        choiceRow("職種", choice: form.jobChoice, otherText: form.otherJob)
      }
      .buttonStyle(.plain)
    }
    .font(.subheadline)
    .padding(.horizontal, 16)
    .background(TechCardBackground(showsBorder: false))
  }

  // 「その他」면 직접 입력한 값을 보여 준다
  private func choiceRow(_ title: LocalizedStringKey, choice: String, otherText: String)
    -> some View
  {
    HStack {
      Text(title)
      Spacer()
      Group {
        if choice.isEmpty {
          Text("選択してください").foregroundStyle(.tertiary)
        } else if choice == ProfileDraft.other, let typed = Profile.trimmed(otherText) {
          Text(typed)
        } else {
          Text(choice)
        }
      }
      .foregroundStyle(.secondary)
      .lineLimit(1)
      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(minHeight: 48)
    .contentShape(Rectangle())
  }

  private var conditions: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 10) {
        ForEach(InterviewType.allCases, id: \.self) { type in
          pill(type.label, symbol: nil, isOn: form.interviewType == type) {
            form.interviewType = type
          }
        }
      }
      HStack(spacing: 10) {
        ForEach(HiringType.allCases, id: \.self) { type in
          pill(type.label, symbol: type.symbolName, isOn: form.hiringType == type) {
            form.hiringType = type
          }
        }
      }
      questionCountRow
    }
  }

  private var questionCountRow: some View {
    let range = AppSettings.questionCountRange
    return HStack(spacing: 12) {
      Text("質問数")
      Spacer()
      stepButton("minus", isEnabled: form.questionCount > range.lowerBound) {
        form.questionCount -= 1
      }
      Text("\(form.questionCount)問")
        .monospacedDigit()
        .frame(minWidth: 40)
      stepButton("plus", isEnabled: form.questionCount < range.upperBound) {
        form.questionCount += 1
      }
    }
    .font(.subheadline)
    .padding(.horizontal, 4)
    // VoiceOver에서는 위아래로 쓸어 값을 바꾼다
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("質問数"))
    .accessibilityValue(Text("\(form.questionCount)問"))
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment: form.questionCount = min(form.questionCount + 1, range.upperBound)
      case .decrement: form.questionCount = max(form.questionCount - 1, range.lowerBound)
      @unknown default: break
      }
    }
  }

  private func stepButton(_ symbol: String, isEnabled: Bool, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.footnote.weight(.semibold))
        .foregroundStyle(TechPalette.accent)
        .frame(width: 34, height: 34)
        .background(Circle().fill(TechPalette.cardTop))
        .overlay { Circle().strokeBorder(TechPalette.accent.opacity(0.3), lineWidth: 1) }
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
    .opacity(isEnabled ? 1 : 0.35)
  }

  private func pill(
    _ title: String, symbol: String?, isOn: Bool, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let symbol {
          // 글자보다 작고 가는 선으로 그린다
          Image(systemName: symbol).font(.footnote.weight(.light))
        }
        Text(title)
      }
      .font(.subheadline.weight(.semibold))
      .foregroundStyle(isOn ? TechPalette.cardBottom : .primary)
      .frame(maxWidth: .infinity, minHeight: 40)
      .background(Capsule().fill(isOn ? TechPalette.accent : TechPalette.cardTop))
      .overlay { Capsule().strokeBorder(TechPalette.accent.opacity(0.3), lineWidth: 1) }
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isOn ? .isSelected : [])
  }
}

#Preview {
  InterviewHomeView()
}
