import AVFoundation

enum AudioSessionConfigurator {
  // 읽기(TTS)와 듣기(STT)를 번갈아 하므로 재생·녹음 겸용으로 설정한다
  static func activate() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(
      .playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
    try session.setActive(true)
  }

  static func deactivate() {
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}
