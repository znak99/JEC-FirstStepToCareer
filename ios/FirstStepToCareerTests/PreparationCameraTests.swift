import Testing

@testable import FirstStepToCareer

struct PreparationCameraTests {
  @Test func faceIDCameraTracksWhenAllowed() {
    #expect(
      PreparationCamera.of(trackingSupported: true, hasFrontCamera: true, accessGranted: true)
        == .faceTracking)
  }

  @Test func frontCameraOnlyShowsMirror() {
    #expect(
      PreparationCamera.of(trackingSupported: false, hasFrontCamera: true, accessGranted: true)
        == .mirror)
  }

  @Test(arguments: [true, false])
  func deniedAccessShowsGuidance(trackingSupported: Bool) {
    #expect(
      PreparationCamera.of(
        trackingSupported: trackingSupported, hasFrontCamera: true, accessGranted: false)
        == .denied)
  }

  @Test(arguments: [true, false])
  func noCameraIsUnavailableWhateverTheAccess(accessGranted: Bool) {
    #expect(
      PreparationCamera.of(
        trackingSupported: false, hasFrontCamera: false, accessGranted: accessGranted)
        == .unavailable)
    #expect(!PreparationCamera.needsAccess(trackingSupported: false, hasFrontCamera: false))
  }
}
