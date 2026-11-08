import Foundation
import Testing

@testable import FirstStepToCareer

@MainActor
struct TabBarVisibilityTests {
  @Test func staysHiddenWhileAnyScreenAsks() {
    let visibility = TabBarVisibility()
    let preparation = UUID()
    let session = UUID()
    #expect(!visibility.isHidden)
    // 준비 화면에서 진행 화면으로 넘어갈 때 두 화면이 잠깐 함께 숨김을 요청한다
    visibility.hide(for: preparation)
    visibility.hide(for: session)
    visibility.show(for: preparation)
    #expect(visibility.isHidden)
    visibility.show(for: session)
    #expect(!visibility.isHidden)
  }

  @Test func sameScreenAskingTwiceNeedsOneShow() {
    let visibility = TabBarVisibility()
    let screen = UUID()
    visibility.hide(for: screen)
    visibility.hide(for: screen)
    visibility.show(for: screen)
    #expect(!visibility.isHidden)
  }

  @Test func showingAnUnknownScreenChangesNothing() {
    let visibility = TabBarVisibility()
    visibility.show(for: UUID())
    #expect(!visibility.isHidden)
    let screen = UUID()
    visibility.hide(for: screen)
    visibility.show(for: UUID())
    #expect(visibility.isHidden)
  }
}
