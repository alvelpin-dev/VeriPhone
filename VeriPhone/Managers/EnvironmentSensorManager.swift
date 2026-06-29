import UIKit
import Combine

/// Sensor de proximidad mediante `UIDevice` (API pública). El sensor de luz
/// ambiental NO tiene una API pública en iOS que devuelva un valor en lux:
/// solo se puede inferir indirectamente observando si el brillo automático
/// de la pantalla cambia, lo cual requiere confirmación manual del usuario.
/// Esa limitación se documenta en la prueba correspondiente (ver
/// `SensorsTestContent`), que solicita al usuario mover el dispositivo entre
/// zonas de luz y oscuridad y confirmar si observa el cambio de brillo.
@MainActor
final class EnvironmentSensorManager: ObservableObject {

    @Published var isProximityNear = false
    @Published var isMonitoringProximity = false

    private var observer: NSObjectProtocol?

    func startProximityMonitoring() {
        UIDevice.current.isProximityMonitoringEnabled = true
        isMonitoringProximity = UIDevice.current.isProximityMonitoringEnabled
        observer = NotificationCenter.default.addObserver(
            forName: UIDevice.proximityStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isProximityNear = UIDevice.current.proximityState
            }
        }
    }

    func stopProximityMonitoring() {
        UIDevice.current.isProximityMonitoringEnabled = false
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
    }
}
