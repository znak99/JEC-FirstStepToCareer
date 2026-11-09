import SwiftUI

extension View {
  // 프로필·동의 기록을 저장하지 못했을 때 알린다. 온보딩의 동의·정보 입력과 메뉴의 프로필이 함께 쓴다
  func saveFailedAlert(for model: ProfileViewModel?) -> some View {
    alert(
      "保存できませんでした",
      isPresented: Binding(get: { model?.saveFailed ?? false }, set: { model?.saveFailed = $0 })
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("しばらくしてから、もう一度お試しください。")
    }
  }
}
