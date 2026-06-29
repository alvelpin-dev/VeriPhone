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
        motionManager.accelerometerUpdateInterval = 1.0 / 30.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            self?.acceleration = data.acceleration
        }
    }

    func startGyroscope() {
        guard motionManager.isGyroAvailable else { return }
        motionManager.gyroUpdateInterval = 1.0 / 30.0
        motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            self?.rotationRate = data.rotationRate
        }
    }

    func startBarometer() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            self?.pressureKPa = data.pressure.doubleValue
            self?.relativeAltitudeMeters = data.relativeAltitude.doubleValue
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
