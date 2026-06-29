import SwiftUI
import CoreMotion

// MARK: - Acelerómetro

struct AccelerometerTestContent: View {
    let onComplete: TestCompletion
    @StateObject private var motion = MotionManager()
    @State private var samples: [LiveMetricSample] = []
    @State private var startTime = Date()
    @State private var maxMagnitude: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Mueve el iPhone para comprobar el acelerómetro.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LiveMetricChartView(title: "Aceleración (g)", unit: "g", samples: samples,
                                 axisColors: ["X": .red, "Y": .green, "Z": .blue])

            Button("Finalizar prueba") {
                if maxMagnitude > 0.15 {
                    onComplete(.pass, "Acelerómetro respondiendo correctamente al movimiento.")
                } else {
                    onComplete(.warning, "No se detectó suficiente movimiento. Intenta mover el dispositivo con más intensidad.")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            guard motion.isAccelerometerAvailable else {
                Task { @MainActor in onComplete(.fail, "Acelerómetro no disponible.") }
                return
            }
            startTime = Date()
            motion.startAccelerometer()
        }
        .onDisappear { motion.stopAll() }
        .onChange(of: motion.acceleration.x) { _, _ in appendSample() }
    }

    private func appendSample() {
        let t = Date().timeIntervalSince(startTime)
        let a = motion.acceleration
        samples.append(LiveMetricSample(time: t, value: a.x, axis: "X"))
        samples.append(LiveMetricSample(time: t, value: a.y, axis: "Y"))
        samples.append(LiveMetricSample(time: t, value: a.z, axis: "Z"))
        if samples.count > 150 { samples.removeFirst(3) }
        maxMagnitude = max(maxMagnitude, sqrt(a.x * a.x + a.y * a.y + a.z * a.z) - 1.0)
    }
}

// MARK: - Giroscopio

struct GyroscopeTestContent: View {
    let onComplete: TestCompletion
    @StateObject private var motion = MotionManager()
    @State private var samples: [LiveMetricSample] = []
    @State private var startTime = Date()
    @State private var maxRate: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Gira el iPhone sobre sus ejes para comprobar el giroscopio.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LiveMetricChartView(title: "Velocidad angular (rad/s)", unit: "rad/s", samples: samples,
                                 axisColors: ["X": .red, "Y": .green, "Z": .blue])

            Button("Finalizar prueba") {
                if maxRate > 0.3 {
                    onComplete(.pass, "Giroscopio respondiendo correctamente al giro.")
                } else {
                    onComplete(.warning, "No se detectó suficiente rotación. Intenta girar el dispositivo con más intensidad.")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            guard motion.isGyroAvailable else {
                Task { @MainActor in onComplete(.fail, "Giroscopio no disponible.") }
                return
            }
            startTime = Date()
            motion.startGyroscope()
        }
        .onDisappear { motion.stopAll() }
        .onChange(of: motion.rotationRate.x) { _, _ in appendSample() }
    }

    private func appendSample() {
        let t = Date().timeIntervalSince(startTime)
        let r = motion.rotationRate
        samples.append(LiveMetricSample(time: t, value: r.x, axis: "X"))
        samples.append(LiveMetricSample(time: t, value: r.y, axis: "Y"))
        samples.append(LiveMetricSample(time: t, value: r.z, axis: "Z"))
        if samples.count > 150 { samples.removeFirst(3) }
        maxRate = max(maxRate, abs(r.x) + abs(r.y) + abs(r.z))
    }
}

// MARK: - Brújula

struct CompassTestContent: View {
    let onComplete: TestCompletion
    @StateObject private var location = LocationManager()

    var body: some View {
        VStack(spacing: 20) {
            if let heading = location.headingDegrees {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 48))
                    .rotationEffect(.degrees(heading))
                    .foregroundStyle(.tint)
                Text("\(Int(heading))°")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            } else {
                ProgressView("Esperando datos de la brújula…")
            }

            Button("Confirmar funcionamiento") {
                if let accuracy = location.headingAccuracyDegrees, accuracy >= 0 {
                    onComplete(.pass, "Brújula respondiendo. Precisión aproximada: \(Int(accuracy))°.")
                } else {
                    onComplete(.warning, "No se pudo confirmar la precisión de la brújula.")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            location.requestPermission()
            location.startUpdatingHeading()
        }
        .onDisappear { location.stopAll() }
    }
}

// MARK: - GPS

struct GPSTestContent: View {
    let onComplete: TestCompletion
    @StateObject private var location = LocationManager()

    var body: some View {
        VStack(spacing: 16) {
            if let loc = location.currentLocation {
                Text(String(format: "%.5f, %.5f", loc.coordinate.latitude, loc.coordinate.longitude))
                    .font(.system(.body, design: .monospaced))
                if let accuracy = location.horizontalAccuracyMeters {
                    Text("Precisión horizontal: ±\(Int(accuracy)) m")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                ProgressView("Obteniendo ubicación…")
            }

            Button("Confirmar resultado") {
                if let accuracy = location.horizontalAccuracyMeters {
                    if accuracy <= 50 {
                        onComplete(.pass, "Ubicación obtenida con precisión de ±\(Int(accuracy)) metros.")
                    } else {
                        onComplete(.warning, "Precisión baja (±\(Int(accuracy)) m). Prueba en exteriores con cielo despejado.")
                    }
                } else {
                    onComplete(.fail, location.errorMessage ?? "No se pudo obtener la ubicación.")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            location.requestPermission()
            location.startUpdatingLocation()
        }
        .onDisappear { location.stopAll() }
    }
}

// MARK: - Barómetro

struct BarometerTestContent: View {
    let onComplete: TestCompletion
    @StateObject private var motion = MotionManager()

    var body: some View {
        VStack(spacing: 16) {
            Text(String(format: "%.2f kPa", motion.pressureKPa))
                .font(.system(size: 36, weight: .bold, design: .rounded))
            Text(String(format: "Altitud relativa: %.1f m", motion.relativeAltitudeMeters))
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Confirmar resultado") {
                if motion.pressureKPa > 0 {
                    onComplete(.pass, "Barómetro reportando presión atmosférica correctamente.")
                } else {
                    onComplete(.fail, "No se recibieron datos del barómetro.")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            guard motion.isBarometerAvailable else {
                Task { @MainActor in onComplete(.skipped, "Barómetro no disponible en este dispositivo.") }
                return
            }
            motion.startBarometer()
        }
        .onDisappear { motion.stopAll() }
    }
}
