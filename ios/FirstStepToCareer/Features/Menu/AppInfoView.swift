import SwiftUI

struct AppInfoView: View {
  private static let repositoryURL = URL(string: "https://github.com/znak99/JEC-FirstStepToCareer")!

  var body: some View {
    List {
      Section {
        LabeledContent("アプリ名", value: String(localized: "就活一歩"))
        LabeledContent("バージョン", value: BuildConfig.appVersion)
      }
      Section {
        Link(destination: Self.repositoryURL) {
          Label("ソースコード（GitHub）", systemImage: "chevron.left.forwardslash.chevron.right")
        }
      } footer: {
        Text("このアプリのソースコードは公開されています。")
      }
    }
    .navigationTitle("アプリ情報")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack { AppInfoView() }
}
