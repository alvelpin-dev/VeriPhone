import SwiftUI

/// Categoría de prueba, usada para agrupar visualmente el diagnóstico.
enum DiagnosticCategory: String, CaseIterable, Codable {
    case battery = "Batería"
    case display = "Pantalla"
    case biometrics = "Biometría"
    case camera = "Cámaras"
    case audio = "Audio"
    case buttons = "Botones"
    case haptics = "Motor háptico"
    case motion = "Movimiento"
    case connectivity = "Conectividad"
    case charging = "Carga"
    case sensors = "Sensores"

    var icon: String {
        switch self {
        case .battery: return "battery.100percent"
        case .display: return "rectangle.inset.filled"
        case .biometrics: return "faceid"
        case .camera: return "camera.fill"
        case .audio: return "waveform"
        case .buttons: return "button.horizontal.top.press.fill"
        case .haptics: return "iphone.radiowaves.left.and.right"
        case .motion: return "gyroscope"
        case .connectivity: return "antenna.radiowaves.left.and.right"
        case .charging: return "bolt.fill"
        case .sensors: return "sensor.tag.radiowaves.forward.fill"
        }
    }
}

/// Resultado de una prueba concreta.
enum TestStatus: String, Codable {
    case pending
    case pass
    case warning
    case fail
    case skipped // hardware no presente en este modelo

    var symbolName: String {
        switch self {
        case .pending: return "circle.dashed"
        case .pass: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .fail: return "xmark.circle.fill"
        case .skipped: return "minus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .gray
        case .pass: return .green
        case .warning: return .orange
        case .fail: return .red
        case .skipped: return .secondary
        }
    }

    var label: String {
        switch self {
        case .pending: return "Pendiente"
        case .pass: return "Correcto"
        case .warning: return "Atención"
        case .fail: return "Error"
        case .skipped: return "No disponible"
        }
    }
}

/// El "tipo" de contenido a renderizar para una prueba; cada caso se
/// corresponde con una vista de detalle especializada.
enum DiagnosticTestKind: String, Codable {
    case battery
    case display
    case colorPattern
    case multitouch
    case faceID
    case touchID
    case rearCamera
    case frontCamera
    case microphone
    case speakers
    case buttons
    case haptics
    case accelerometer
    case gyroscope
    case compass
    case gps
    case bluetooth
    case wifi
    case cellular
    case nfc
    case charging
    case proximity
    case ambientLight
    case lidar
    case barometer
    case dynamicIsland
    case alwaysOnDisplay
}

/// Definición declarativa de una prueba dentro del diagnóstico.
struct DiagnosticTest: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let category: DiagnosticCategory
    let kind: DiagnosticTestKind
    let isAutomatic: Bool
    let limitationNote: String?

    static func == (lhs: DiagnosticTest, rhs: DiagnosticTest) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Resultado final asociado a una prueba, una vez ejecutada.
struct TestResult: Identifiable {
    let id: String          // == DiagnosticTest.id
    var status: TestStatus
    var message: String
}
