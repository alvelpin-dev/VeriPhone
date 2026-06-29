import Foundation

/// Tipo de conector físico de carga/datos.
enum ConnectorType: String, Codable {
    case lightning = "Lightning"
    case usbC = "USB-C"
}

/// Modelo de datos con las características de hardware de un iPhone concreto.
///
/// Estos datos se obtienen de las especificaciones públicas de Apple para cada
/// identificador de modelo (`hw.machine`). No existe ninguna API pública que
/// devuelva estas capacidades directamente: por eso se mantiene esta base de
/// datos local, indexada por identificador interno.
struct DeviceModel: Identifiable, Codable, Hashable {
    var id: String { identifier }

    let identifier: String          // p.ej. "iPhone15,2"
    let marketingName: String       // p.ej. "iPhone 14 Pro"
    let year: Int
    let chip: String

    // Pantalla
    let screenSizeInches: Double
    let hasTrueTone: Bool
    let hasProMotion: Bool
    let hasDynamicIsland: Bool
    let hasAlwaysOnDisplay: Bool

    // Biometría
    let hasFaceID: Bool
    let hasTouchID: Bool
    let touchIDLocation: TouchIDLocation

    // Cámaras
    let rearCameraCount: Int
    let hasUltraWideCamera: Bool
    let hasTelephotoCamera: Bool
    let hasMacroCamera: Bool
    let hasLiDAR: Bool
    let hasOpticalZoom: Bool

    // Conectividad y carga
    let connector: ConnectorType
    let supportsMagSafe: Bool
    let supportsWirelessCharging: Bool
    let supportsFastCharging: Bool
    let hasNFC: Bool
    let hasUltraWideband: Bool // U1/U2 chip

    // Sensores
    let hasBarometer: Bool
    let hasGyroscope: Bool
    let hasCompass: Bool
    let hasProximitySensor: Bool
    let hasAmbientLightSensor: Bool

    // Botones físicos
    let hasActionButton: Bool
    let hasHomeButton: Bool
    let hasMuteSwitch: Bool

    // Audio
    let hasStereoSpeakers: Bool
    let microphoneCount: Int

    enum TouchIDLocation: String, Codable {
        case home = "Botón Home"
        case sidePower = "Botón lateral"
        case none = "No disponible"
    }
}
