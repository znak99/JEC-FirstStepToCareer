import Foundation

// 빌드 설정(xcconfig)에서 Info.plist로 넘어온 값
enum BuildConfig {
  // 무료 Apple 계정 빌드에서는 Apple 로그인을 쓸 수 없어 기본값은 꺼짐이다
  static var appleSignInEnabled: Bool {
    Bundle.main.object(forInfoDictionaryKey: "APPLE_SIGN_IN_ENABLED") as? String == "YES"
  }

  static var appVersion: String {
    let info = Bundle.main.infoDictionary
    let version = info?["CFBundleShortVersionString"] as? String ?? "-"
    let build = info?["CFBundleVersion"] as? String ?? "-"
    return "\(version) (\(build))"
  }

  static var appInfo: AppInfo {
    AppInfo(version: appVersion, appleSignInEnabled: appleSignInEnabled)
  }
}
