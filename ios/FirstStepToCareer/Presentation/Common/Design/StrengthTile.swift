import SwiftUI

// 강점·약점처럼 이름과 값을 색으로 구분해 보여 주는 작은 칸. 분석 화면과 면접 결과 화면이 함께 쓴다
struct StrengthTile: View {
  let title: LocalizedStringKey
  let value: String
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.caption).foregroundStyle(.secondary)
      Text(verbatim: value).font(.subheadline.weight(.semibold)).foregroundStyle(tint)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint.opacity(0.1)))
    .accessibilityElement(children: .combine)
  }
}
