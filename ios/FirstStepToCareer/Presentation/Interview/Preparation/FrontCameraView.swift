import AVFoundation
import SwiftUI

// 앞쪽 카메라 영상을 화면 가득 보여 준다. 앞쪽 카메라라 거울처럼 좌우가 뒤집혀 보인다
struct FrontCameraView: UIViewRepresentable {
  let session: AVCaptureSession

  func makeUIView(context: Context) -> PreviewView {
    let view = PreviewView()
    view.previewLayer.session = session
    view.previewLayer.videoGravity = .resizeAspectFill
    return view
  }

  func updateUIView(_ uiView: PreviewView, context: Context) {}

  final class PreviewView: UIView {
    let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame: CGRect) {
      super.init(frame: frame)
      layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
      super.layoutSubviews()
      previewLayer.frame = bounds
    }
  }
}
