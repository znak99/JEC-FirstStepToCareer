import SwiftUI

// 어떤 데이터를 어디에 저장·전송하는지 안내한다 (SITE_MAP S-10)
struct PrivacyView: View {
  var body: some View {
    List {
      item(
        "映像と音声", systemImage: "video.slash",
        text:
          "カメラの映像とマイクの音声は、保存も送信もしません。視線と頭の動きは、このiPhoneの中だけで計算します。"
      )
      item(
        "サーバーに保存するデータ", systemImage: "externaldrive",
        text:
          "面接の設定（会社名・業種・職種など）、文字に起こした回答、視線と頭の動きの減点回数、点数とフィードバックをサーバーに保存します。保存したデータは運営者が見ることができます。"
      )
      item(
        "AIへの送信", systemImage: "sparkles",
        text: "質問の作成と評価のために、面接の設定と文字に起こした回答をAnthropic社のClaude APIへ送信します。")
      item(
        "Appleでログイン", systemImage: "apple.logo",
        text: "Appleアカウントのメールアドレスと名前は受け取らず、保存もしません。")
      item(
        "データの削除", systemImage: "trash",
        text: "メニューの「すべてのデータを削除」から、サーバーに保存された記録をいつでもすべて削除できます。")
    }
    .navigationTitle("個人情報の取り扱い")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func item(_ title: LocalizedStringKey, systemImage: String, text: LocalizedStringKey)
    -> some View
  {
    Section {
      Text(text).font(.callout)
    } header: {
      Label(title, systemImage: systemImage)
    }
  }
}

#Preview {
  NavigationStack { PrivacyView() }
}
