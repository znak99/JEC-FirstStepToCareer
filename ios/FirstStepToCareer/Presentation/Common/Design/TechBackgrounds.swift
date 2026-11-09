import SwiftUI

struct TechCardBackground: View {
  // 온보딩 동의 카드처럼 테두리 없이 쓸 때 false
  var showsBorder = true

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
    shape
      .fill(
        LinearGradient(
          colors: [TechPalette.cardTop, TechPalette.cardBottom], startPoint: .topLeading,
          endPoint: .bottomTrailing)
      )
      .overlay { DotGrid().clipShape(shape) }
      .overlay {
        if showsBorder {
          shape.strokeBorder(
            LinearGradient(
              colors: [TechPalette.accent.opacity(0.55), TechPalette.accent.opacity(0.05)],
              startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }
      }
  }
}

// 화면 전체의 바탕. 어두운 모드는 검은색에 가깝다
struct TechPageBackground: View {
  var body: some View {
    LinearGradient(
      colors: [TechPalette.pageTop, TechPalette.pageBottom], startPoint: .top, endPoint: .bottom
    )
    .overlay { DotGrid() }
    .ignoresSafeArea()
  }
}

// 앱 아이콘과 같은 도트 무늬
struct DotGrid: View {
  var body: some View {
    Canvas { context, size in
      let spacing: CGFloat = 14
      var path = Path()
      for x in stride(from: spacing / 2, to: size.width, by: spacing) {
        for y in stride(from: spacing / 2, to: size.height, by: spacing) {
          path.addEllipse(in: CGRect(x: x - 0.75, y: y - 0.75, width: 1.5, height: 1.5))
        }
      }
      context.fill(path, with: .color(TechPalette.ink.opacity(0.07)))
    }
    .allowsHitTesting(false)
  }
}
