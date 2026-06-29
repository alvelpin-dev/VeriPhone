import LocalAuthentication

/// Comprueba el funcionamiento de Face ID / Touch ID mediante `LocalAuthentication`.
///
/// Nota de limitación: esta API confirma que el sensor biométrico autentica
/// correctamente contra los datos ya inscritos en el Secure Enclave, pero no
/// expone ningún diagnóstico interno de fábrica del sensor (eso solo está
/// disponible mediante herramientas internas de Apple). En particular, iOS no
/// ofrece ninguna forma pública de activar la cámara TrueDepth o el sensor
/// capacitivo sin pasar por el asistente de inscripción de Ajustes: si ese
/// asistente falla al intentar inscribir un rostro o huella, es en sí mismo
/// una señal fuerte de que el sensor tiene un problema de hardware, y esta
/// prueba lo refleja como tal en lugar de limitarse a decir "no disponible".
enum BiometricKind {
    case faceID, touchID, none
}

enum BiometricAvailability {
    case ready(BiometricKind)           // configurado, listo para autenticar
    case notEnrolled(BiometricKind)     // hardware presente pero sin inscribir
    case unavailable                    // sin hardware biométrico en este dispositivo
}

@MainActor
final class BiometricManager: ObservableObject {

    @Published var lastResultMessage: String = ""
    @Published var lastSucceeded: Bool? = nil

    /// A diferencia de `canEvaluatePolicy`, `biometryType` refleja el hardware
    /// presente incluso si el usuario no ha inscrito ningún rostro/huella
    /// todavía, lo que permite distinguir "no inscrito" de "sin sensor".
    func availability() -> BiometricAvailability {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        let kind: BiometricKind
        switch context.biometryType {
        case .faceID: kind = .faceID
        case .touchID: kind = .touchID
        default: kind = .none
        }

        if canEvaluate {
            return kind == .none ? .unavailable : .ready(kind)
        }

        if let laError = error as? LAError, laError.code == .biometryNotEnrolled, kind != .none {
            return .notEnrolled(kind)
        }
        return .unavailable
    }

    func runAuthentication(reason: String) async {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            lastSucceeded = false
            if let laError = error as? LAError, laError.code == .biometryNotEnrolled {
                lastResultMessage = "El sensor está presente pero no hay ningún rostro/huella inscrito en este iPhone. Si al intentar configurarlo en Ajustes el asistente de inscripción falla o no detecta tu rostro/huella, es una señal de que el sensor biométrico no funciona correctamente."
            } else {
                lastResultMessage = error?.localizedDescription ?? "Biometría no disponible en este dispositivo."
            }
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
