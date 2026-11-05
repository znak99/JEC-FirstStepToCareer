import SwiftUI

struct ScheduleCalendarView: View {
  var body: some View {
    NavigationStack {
      ContentUnavailableView("準備中", systemImage: "calendar")
        .navigationTitle("日程")
    }
  }
}

#Preview {
  ScheduleCalendarView()
}
