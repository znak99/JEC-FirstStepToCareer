import SwiftUI

// 면접관 아이콘. 질문을 읽거나 채점하는 동안(isActive) 둘레에 고리가 천천히 퍼진다.
// '동작 줄이기'가 켜져 있으면 멈춘 고리를 보여 준다
struct InterviewerAvatar: View {
  let isActive: Bool

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private let size: CGFloat = 104
  private let spread: CGFloat = 1.45

  var body: some View {
    VStack(spacing: 8) {
      ZStack {
        if isActive { rings }
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
