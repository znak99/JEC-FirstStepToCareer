import SwiftUI

enum AppTab: CaseIterable, Hashable {
  case interview
  case schedule
  case analytics

  var title: LocalizedStringKey {
    switch self {
    case .interview: "面接"
    case .schedule: "日程"
    case .analytics: "分析"
    }
  }

  var systemImage: String {
    switch self {
    case .interview: "person.wave.2"
    case .schedule: "calendar"
    case .analytics: "chart.xyaxis.line"
    }
  }
}
