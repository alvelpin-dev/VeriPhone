import SwiftUI

struct BiometricTestContent: View {
    let kind: DiagnosticTestKind
    let onComplete: TestCompletion

    @StateObject private var manager = BiometricManager()
    @State private var isAuthenticating = false

    private var symbol: String { kind == .faceID ? "faceid" : "touchid" }
    private var reason: String { kind == .faceID ? "Comprobar el funcionamiento de Face ID" : "Comprobar el funcionamiento de Touch ID" }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: symbol)
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Pulsa el botón y autentícate con el sensor biométrico cuando el sistema te lo solicite.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

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
    }

    private func authenticate() async {
        isAuthenticating = true
        await manager.runAuthentication(reason: reason)
        isAuthenticating = false
        if manager.lastSucceeded == true {
            onComplete(.pass, manager.lastResultMessage)
        } else {
            onComplete(.warning, manager.lastResultMessage)
        }
    }
}
