import SwiftUI

struct InterviewHomeView: View {
  @Environment(\.apiClient) private var api
  @State private var path: [InterviewRoute] = []
  @State private var availability = Availability.loading

  enum Availability: Equatable {
    case loading
    case available
    case aiDisabled
    case failed
  }

  var body: some View {
    NavigationStack(path: $path) {
      VStack(spacing: 24) {
        Spacer()
        Image(systemName: "person.wave.2")
          .font(.system(size: 64))
          .foregroundStyle(.tint)
        Text("AI面接官と模擬面接")
          .font(.title2.bold())
        statusMessage
        Spacer()
        Button {
          path.append(.setup)
        } label: {
          Text("面接を始める")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(availability != .available)
      }
      .padding()
      .navigationTitle("面接")
      .navigationDestination(for: InterviewRoute.self) { route in
        switch route {
        case .setup:
          InterviewSetupView { draft in path.append(.preparation(draft)) }
        case .preparation(let draft):
          PreparationView(draft: draft) { context in path.append(.session(context)) }
        case .session(let context):
          InterviewSessionView(context: context)
        }
      }
      .task { await refresh() }
      .refreshable { await refresh() }
    }
  }

  @ViewBuilder
  private var statusMessage: some View {
    switch availability {
    case .loading:
      ProgressView()
    case .available:
      Label("AI面接を利用できます", systemImage: "checkmark.circle")
        .foregroundStyle(.secondary)
    case .aiDisabled:
      Label("現在、AI機能は停止中です。", systemImage: "pause.circle")
        .foregroundStyle(.secondary)
    case .failed:
      VStack(spacing: 8) {
        Label("サーバーに接続できませんでした。", systemImage: "wifi.exclamationmark")
          .foregroundStyle(.secondary)
        Button("再試行") { Task { await refresh() } }
      }
    }
  }

  private func refresh() async {
    availability = .loading
    do {
      availability = try await api.status().aiEnabled ? .available : .aiDisabled
    } catch {
      availability = .failed
    }
  }
}

#Preview {
  InterviewHomeView()
}
