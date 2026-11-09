import AuthenticationServices
import SwiftUI

// 메뉴와 시작 화면에서 함께 쓰는 Apple 로그인 버튼. 이메일과 이름은 요청하지 않는다
struct AppleSignInButton: View {
  var height: CGFloat = 44
  let onSignedIn: (AppleSignInRequest) -> Void
  let onFailed: () -> Void

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.useCases) private var useCases
  @State private var nonce = ""

  var body: some View {
    SignInWithAppleButton(.signIn) { request in
      guard let challenge = useCases?.makeSignInChallenge.execute() else { return }
      nonce = challenge.nonce
      request.requestedScopes = []
      request.nonce = challenge.hashedNonce
    } onCompletion: { result in
      switch result {
      case .success(let authorization):
        guard
          let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
          let data = credential.identityToken,
          let token = String(data: data, encoding: .utf8)
        else {
          onFailed()
          return
        }
        onSignedIn(AppleSignInRequest(identityToken: token, nonce: nonce))
      case .failure(let error):
        // 사용자가 스스로 닫은 경우는 오류로 알리지 않는다
        if (error as? ASAuthorizationError)?.code == .canceled { return }
        onFailed()
      }
    }
    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
    // 앱을 켠 채로 밝은/어두운 모드를 바꾸면 버튼 색이 그대로라 새로 만든다
    .id(colorScheme)
    .frame(height: height)
  }
}
