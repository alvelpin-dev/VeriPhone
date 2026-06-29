import SwiftUI

struct BiometricTestContent: View {
    let kind: DiagnosticTestKind
    let onComplete: TestCompletion

    @StateObject private var manager = BiometricManager()
    @State private var isAuthenticating = false
    @State private var availability: BiometricAvailability = .unavailable

    private var symbol: String { kind == .faceID ? "faceid" : "touchid" }
    private var reason: String { kind == .faceID ? "Comprobar el funcionamiento de Face ID" : "Comprobar el funcionamiento de Touch ID" }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: symbol)
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            switch availability {
            case .ready:
                Text("Pulsa el botón y autentícate con el sensor biométrico cuando el sistema te lo solicite.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .notEnrolled:
                VStack(spacing: 8) {
                    Label("Sensor presente, pero sin inscribir", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text("Ve a Ajustes y trata de configurar \(kind == .faceID ? "Face ID" : "Touch ID"). Si el asistente de inscripción falla repetidamente al detectar tu rostro/huella, es una señal de que el sensor podría tener un problema de hardware.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            case .unavailable:
                Text("El sistema no reporta sensor biométrico disponible.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await authenticate() }
            } label: {
                if isAuthenticating {
                    ProgressView()
                } else {
                    Text("Solicitar autenticación")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAuthenticating)
        }
        .onAppear { availability = manager.availability() }
    }

    private func authenticate() async {
        isAuthenticating = true
        await manager.runAuthentication(reason: reason)
        isAuthenticating = false
        availability = manager.availability()
        if manager.lastSucceeded == true {
            onComplete(.pass, manager.lastResultMessage)
        } else {
            onComplete(.warning, manager.lastResultMessage)
        }
    }
}
