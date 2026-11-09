import SwiftUI

enum AppTab: CaseIterable, Hashable {
  case interview
  case history
  case menu

  var title: LocalizedStringKey {
    switch self {
    case .interview: "面接"
    case .history: "記録"
    case .menu: "メニュー"
    }
  }

  var systemImage: String {
    switch self {
    case .interview: "person.wave.2"
    case .history: "chart.xyaxis.line"
    case .menu: "line.3.horizontal"
    }
  }
}
