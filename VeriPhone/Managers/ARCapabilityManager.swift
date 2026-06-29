import ARKit
import Combine

/// Comprueba la disponibilidad e inicialización del sensor LiDAR mediante
/// ARKit. `supportsSceneReconstruction(.mesh)` solo devuelve `true` en
/// dispositivos con escáner LiDAR físico, por lo que es la mejor señal
/// pública disponible para confirmar su presencia y funcionamiento básico.
@MainActor
final class ARCapabilityManager: NSObject, ObservableObject {

    @Published var isSessionRunning = false
    @Published var meshAnchorsDetected = 0
    @Published var errorMessage: String?

    private var session: ARSession?

    var supportsLiDARMeshing: Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }

    func startSceneReconstructionTest() {
        guard supportsLiDARMeshing else {
            errorMessage = "Este dispositivo no tiene escáner LiDAR."
            return
        }
        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .mesh

        let session = ARSession()
        session.delegate = self
        self.session = session
        session.run(configuration)
        isSessionRunning = true
    }

    func stop() {
        session?.pause()
        session = nil
        isSessionRunning = false
    }
}

extension ARCapabilityManager: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let meshCount = anchors.filter { $0 is ARMeshAnchor }.count
        guard meshCount > 0 else { return }
        Task { @MainActor in self.meshAnchorsDetected += meshCount }
    }

    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in self.errorMessage = error.localizedDescription }
    }
}
