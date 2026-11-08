import ARKit
import SceneKit
import SwiftUI
import Synchronization

// 카메라 영상 위에 ARKit이 인식한 얼굴 그물망, 눈·코·입 점, 시선 방향 선을 겹쳐 그린다.
// 영상은 화면에 보여 주기만 하고 저장하거나 보내지 않는다
struct FaceCameraView: UIViewRepresentable {
  let session: ARSession
  // 면접 진행 화면의 작은 내 화면처럼 영상만 보여 줄 때 false
  var showsFaceOverlay = true

  func makeCoordinator() -> FaceOverlayRenderer { FaceOverlayRenderer() }

  func makeUIView(context: Context) -> ARSCNView {
    let view = ARSCNView()
    view.session = session
    if showsFaceOverlay { view.delegate = context.coordinator }
    view.automaticallyUpdatesLighting = false
    return view
  }

  func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

// SceneKit 렌더링 스레드에서 불린다. 메인 액터 상태는 건드리지 않는다
final class FaceOverlayRenderer: NSObject, ARSCNViewDelegate {
  private enum Name {
    static let leftEye = "leftEye"
    static let rightEye = "rightEye"
    static let nose = "nose"
    static let mouth = "mouth"
  }

  private let landmarks = Mutex<FaceLandmarks?>(nil)

  nonisolated func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    guard let faceAnchor = anchor as? ARFaceAnchor, let device = renderer.device,
      let geometry = ARSCNFaceGeometry(device: device)
    else { return nil }
    let mesh = SCNMaterial()
    mesh.fillMode = .lines
    mesh.lightingModel = .constant
    mesh.diffuse.contents = UIColor.white.withAlphaComponent(0.45)
    geometry.firstMaterial = mesh

    let node = SCNNode(geometry: geometry)
    node.addChildNode(Self.eyeNode(name: Name.leftEye))
    node.addChildNode(Self.eyeNode(name: Name.rightEye))
    node.addChildNode(Self.dot(name: Name.nose, color: .systemOrange))
    node.addChildNode(Self.dot(name: Name.mouth, color: .systemPink))
    landmarks.withLock { value in
      if value == nil { value = FaceLandmarks(geometry: faceAnchor.geometry) }
    }
    return node
  }

  nonisolated func renderer(
    _ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor
  ) {
    guard let faceAnchor = anchor as? ARFaceAnchor,
      let geometry = node.geometry as? ARSCNFaceGeometry
    else { return }
    geometry.update(from: faceAnchor.geometry)
    node.childNode(withName: Name.leftEye, recursively: false)?.simdTransform =
      faceAnchor.leftEyeTransform
    node.childNode(withName: Name.rightEye, recursively: false)?.simdTransform =
      faceAnchor.rightEyeTransform

    guard let landmarks = landmarks.withLock({ $0 }) else { return }
    let vertices = faceAnchor.geometry.vertices
    node.childNode(withName: Name.nose, recursively: false)?.simdPosition =
      vertices[landmarks.noseTip]
    if !landmarks.mouth.isEmpty {
      let sum = landmarks.mouth.reduce(SIMD3<Float>()) { $0 + vertices[$1] }
      node.childNode(withName: Name.mouth, recursively: false)?.simdPosition =
        sum / Float(landmarks.mouth.count)
    }
  }

  // 눈 위치의 점과, 눈이 향하는 방향(+z)으로 뻗은 선
  private nonisolated static func eyeNode(name: String) -> SCNNode {
    let eye = dot(name: name, color: .systemCyan)
    let length: CGFloat = 0.15
    let ray = SCNNode(geometry: SCNCylinder(radius: 0.0012, height: length))
    ray.geometry?.firstMaterial = material(color: .systemYellow)
    ray.eulerAngles.x = .pi / 2
    ray.position.z = Float(length / 2)
    eye.addChildNode(ray)
    return eye
  }

  private nonisolated static func dot(name: String, color: UIColor) -> SCNNode {
    let node = SCNNode(geometry: SCNSphere(radius: 0.004))
    node.geometry?.firstMaterial = material(color: color)
    node.name = name
    node.renderingOrder = 10
    return node
  }

  private nonisolated static func material(color: UIColor) -> SCNMaterial {
    let material = SCNMaterial()
    material.lightingModel = .constant
    material.diffuse.contents = color
    material.readsFromDepthBuffer = false
    return material
  }
}

// 얼굴 그물망에서 코끝과 입 둘레 꼭짓점을 찾는다. 그물망의 연결 구조는 늘 같으므로 한 번만 계산한다
struct FaceLandmarks: Sendable {
  let noseTip: Int
  let mouth: [Int]

  init?(geometry: ARFaceGeometry) {
    let vertices = geometry.vertices
    guard !vertices.isEmpty else { return nil }
    // 코끝은 얼굴 앞쪽(+z)으로 가장 튀어나온 꼭짓점이다
    noseTip = vertices.indices.max { vertices[$0].z < vertices[$1].z } ?? 0
    mouth = Self.mouthLoop(geometry: geometry)
  }

  // 그물망에는 얼굴 가장자리, 두 눈, 입 자리에 구멍이 있다.
  // 삼각형 하나에만 속한 변을 이어 구멍 둘레를 만들고, 가장자리를 뺀 둘레 중 가장 아래쪽을 입으로 본다
  private static func mouthLoop(geometry: ARFaceGeometry) -> [Int] {
    let vertices = geometry.vertices
    let triangles = geometry.triangleIndices
    var edgeCounts: [Int: Int] = [:]
    for triangle in 0..<geometry.triangleCount {
      let corners = (0..<3).map { Int(triangles[triangle * 3 + $0]) }
      for i in 0..<3 {
        let a = corners[i]
        let b = corners[(i + 1) % 3]
        edgeCounts[min(a, b) * vertices.count + max(a, b), default: 0] += 1
      }
    }

    var parent = Array(vertices.indices)
    func root(_ vertex: Int) -> Int {
      var current = vertex
      while parent[current] != current {
        parent[current] = parent[parent[current]]
        current = parent[current]
      }
      return current
    }
    var boundary = Set<Int>()
    for (edge, count) in edgeCounts where count == 1 {
      let a = edge / vertices.count
      let b = edge % vertices.count
      boundary.insert(a)
      boundary.insert(b)
      parent[root(a)] = root(b)
    }

    let loops = Dictionary(grouping: boundary, by: root).values.sorted { $0.count > $1.count }
    guard loops.count >= 2 else { return [] }
    let meanY: ([Int]) -> Float = { loop in
      loop.reduce(0) { $0 + vertices[$1].y } / Float(loop.count)
    }
    return loops.dropFirst().min { meanY($0) < meanY($1) } ?? []
  }
}
