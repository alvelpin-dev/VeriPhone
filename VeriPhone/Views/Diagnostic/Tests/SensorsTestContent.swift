import SwiftUI

// MARK: - Proximidad

struct ProximityTestContent: View {
    let onComplete: TestCompletion
    @StateObject private var sensor = EnvironmentSensorManager()
    @State private var observedNear = false
    @State private var observedFar = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: sensor.isProximityNear ? "hand.raised.fill" : "hand.raised")
                .font(.system(size: 48))
                .foregroundStyle(sensor.isProximityNear ? .blue : .secondary)

            Text("Tapa y descubre el sensor de proximidad (junto a la cámara frontal) varias veces.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Finalizar prueba") {
                if observedNear && observedFar {
                    onComplete(.pass, "Sensor de proximidad respondiendo correctamente en ambos estados.")
                } else {
                    onComplete(.warning, "No se detectaron ambos estados (tapado/descubierto) del sensor.")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear { sensor.startProximityMonitoring() }
        .onDisappear { sensor.stopProximityMonitoring() }
        .onChange(of: sensor.isProximityNear) { _, isNear in
            if isNear { observedNear = true } else { observedFar = true }
        }
    }
}

// MARK: - Luz ambiental

struct AmbientLightTestContent: View {
    let onComplete: TestCompletion

    var body: some View {
        ManualConfirmView(
            icon: "sun.max.fill",
            instruction: "Activa el brillo automático en Ajustes y mueve el iPhone entre una zona muy iluminada y otra oscura.",
            question: "¿Observas que el brillo de la pantalla se ajusta automáticamente?"
        ) { confirmed in
            if confirmed {
                onComplete(.pass, "El usuario confirmó el ajuste automático de brillo según la luz ambiental.")
            } else {
                onComplete(.fail, "El usuario no observó ajuste automático de brillo.")
            }
        }
    }
}

// MARK: - LiDAR

struct LiDARTestContent: View {
    let onComplete: TestCompletion
    @StateObject private var ar = ARCapabilityManager()

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            if ar.isSessionRunning {
                Text("Anclas de malla detectadas: \(ar.meshAnchorsDetected)")
                    .font(.subheadline)
                Text("Mueve el iPhone apuntando a distintas superficies de la habitación.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button("Finalizar prueba LiDAR") {
                if ar.meshAnchorsDetected > 0 {
                    onComplete(.pass, "El sensor LiDAR generó \(ar.meshAnchorsDetected) anclas de malla correctamente.")
                } else {
                    onComplete(.warning, "No se generaron anclas de malla todavía. Mueve el dispositivo apuntando a superficies cercanas.")
                }
                ar.stop()
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear { ar.startSceneReconstructionTest() }
        .onDisappear { ar.stop() }
    }
}

// MARK: - Dynamic Island

struct DynamicIslandTestContent: View {
    let onComplete: TestCompletion
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(.black)
                .frame(width: expanded ? 220 : 120, height: expanded ? 38 : 28)
                .overlay {
                    if expanded {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("Dynamic Island").foregroundStyle(.white).font(.caption)
                        }
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: expanded)
                .onTapGesture { expanded.toggle() }

            Text("Toca la cápsula para simular una expansión de Dynamic Island.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Confirmar visualización") {
                onComplete(.pass, "Animación de demostración de Dynamic Island mostrada correctamente. Esta es una simulación visual: iOS no permite a apps de terceros forzar el contenido real de la Dynamic Island fuera de Live Activities.")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 40)
    }
}

// MARK: - Always-On Display

struct AlwaysOnDisplayTestContent: View {
    let device: DeviceModel
    let onComplete: TestCompletion

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Este modelo admite Always-On Display según su ficha técnica.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Text("Bloquea el dispositivo y comprueba visualmente si la pantalla permanece atenuada mostrando la hora.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ManualConfirmView(
                icon: "lock.display",
                instruction: "Tras bloquear el dispositivo,",
                question: "¿La pantalla se mantiene atenuada mostrando información?"
            ) { confirmed in
                if confirmed {
                    onComplete(.pass, "El usuario confirmó el comportamiento de Always-On Display.")
                } else {
                    onComplete(.fail, "El usuario no observó el comportamiento esperado de Always-On Display.")
                }
            }
        }
    }
}
