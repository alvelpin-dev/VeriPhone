import LocalAuthentication

/// Comprueba el funcionamiento de Face ID / Touch ID mediante `LocalAuthentication`.
///
/// Nota de limitación: esta API confirma que el sensor biométrico autentica
/// correctamente contra los datos ya inscritos en el Secure Enclave, pero no
/// expone ningún diagnóstico interno de fábrica del sensor (eso solo está
/// disponible mediante herramientas internas de Apple).
enum BiometricKind {
    case faceID, touchID, none
}

@MainActor
final class BiometricManager: ObservableObject {

    @Published var lastResultMessage: String = ""
    @Published var lastSucceeded: Bool? = nil

    func availableBiometric() -> BiometricKind {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .none
        }
    }

    func runAuthentication(reason: String) async {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            lastSucceeded = false
            lastResultMessage = error?.localizedDescription ?? "Biometría no disponible o no configurada."
            return
        }
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            lastSucceeded = success
            lastResultMessage = success ? "Autenticación correcta." : "Autenticación fallida."
        } catch let laError as LAError {
            lastSucceeded = false
            lastResultMessage = laError.localizedDescription
        } catch {
            lastSucceeded = false
            lastResultMessage = error.localizedDescription
        }
    }
}
