import CoreMotion
import Combine

/// Lecturas en vivo de acelerómetro, giroscopio, brújula y barómetro.
@MainActor
final class MotionManager: ObservableObject {

    @Published var acceleration: CMAcceleration = .init(x: 0, y: 0, z: 0)
    @Published var rotationRate: CMRotationRate = .init(x: 0, y: 0, z: 0)
    @Published var headingDegrees: Double = 0
    @Published var pressureKPa: Double = 0
    @Published var relativeAltitudeMeters: Double = 0

    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()

    func startAccelerometer() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 20.0
        // CoreMotion solo garantiza que el closure se entregue en la cola
        // indicada (`.main`), no que corra ya bajo el executor de MainActor.
        // Saltamos explícitamente con Task { @MainActor in } para evitar un
        // posible crash de "incorrect actor executor assumption" al mutar
        // propiedades @Published aisladas a MainActor desde ese closure.
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            let acceleration = data.acceleration
            Task { @MainActor in
                self?.acceleration = acceleration
            }
        }
    }

    func startGyroscope() {
        guard motionManager.isGyroAvailable else { return }
        motionManager.gyroUpdateInterval = 1.0 / 20.0
        motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            let rotationRate = data.rotationRate
            Task { @MainActor in
                self?.rotationRate = rotationRate
            }
        }
    }

    func startBarometer() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            let pressure = data.pressure.doubleValue
            let altitude = data.relativeAltitude.doubleValue
            Task { @MainActor in
                self?.pressureKPa = pressure
                self?.relativeAltitudeMeters = altitude
            }
        }
    }

    func stopAll() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        altimeter.stopRelativeAltitudeUpdates()
    }

    var isAccelerometerAvailable: Bool { motionManager.isAccelerometerAvailable }
    var isGyroAvailable: Bool { motionManager.isGyroAvailable }
    var isBarometerAvailable: Bool { CMAltimeter.isRelativeAltitudeAvailable() }
}
