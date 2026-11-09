import SwiftUI

// 앱 아이콘의 흰 그림(머리·몸·책상·다리 4개). 아이콘 1024 좌표를 그대로 옮겨 온다
enum SplashLogo {
  static let box = CGRect(x: 164, y: 185, width: 697, height: 679)

  static func size(width: CGFloat) -> CGSize {
    CGSize(width: width, height: width * box.height / box.width)
  }

  // 선으로 그리는 순서대로 돌려준다
  static func parts(in rect: CGRect) -> [Path] {
    let s = min(rect.width / box.width, rect.height / box.height)
    let ox = rect.midX - box.midX * s
    let oy = rect.midY - box.midY * s
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
    func frame(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
      CGRect(x: ox + x * s, y: oy + y * s, width: w * s, height: h * s)
    }
    let head = Path(ellipseIn: frame(432.5, 185, 158, 158))
    let body = UnevenRoundedRectangle(
      topLeadingRadius: 120 * s, bottomLeadingRadius: 8 * s, bottomTrailingRadius: 8 * s,
      topTrailingRadius: 120 * s
    ).path(in: frame(352, 352, 320, 160))
    let corners = [point(185, 536), point(838, 536), point(859, 656), point(164, 656)]
    var table = Path()
    table.move(to: CGPoint(x: (corners[0].x + corners[1].x) / 2, y: corners[0].y))
    for index in 1...4 {
      table.addArc(
        tangent1End: corners[index % 4], tangent2End: corners[(index + 1) % 4], radius: 10 * s)
    }
    table.closeSubpath()
    let legs = [(184.0, 864.0), (232.0, 816.0), (768.0, 816.0), (816.0, 864.0)].map { x, bottom in
      UnevenRoundedRectangle(
        topLeadingRadius: 0, bottomLeadingRadius: 12 * s, bottomTrailingRadius: 12 * s,
        topTrailingRadius: 0
      ).path(in: frame(x, 656, 24, bottom - 656))
    }
    return [head, body, table] + legs
  }
}
