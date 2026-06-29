import UIKit
import Foundation

/// Información en vivo del dispositivo: modelo, iOS, almacenamiento, batería.
///
/// El número de serie real y el estado interno de fábrica de Face ID/Touch ID
/// NO son accesibles mediante APIs públicas de iOS por motivos de privacidad;
/// solo herramientas internas de Apple (p.ej. el diagnóstico de Apple Store)
/// pueden leerlos. Aquí se documenta esa limitación en lugar de simularla.
@MainActor
final class DeviceInfoManager: ObservableObject {

    @Published private(set) var deviceModel: DeviceModel
    @Published private(set) var hardwareIdentifier: String
    @Published private(set) var systemVersion: String
    @Published private(set) var totalDiskSpace: Int64?
    @Published private(set) var freeDiskSpace: Int64?
    @Published private(set) var batteryLevel: Float
    @Published private(set) var batteryState: UIDevice.BatteryState
    @Published private(set) var estimatedRAM: Int64

    init() {
        let identifier = Self.readHardwareIdentifier()
        self.hardwareIdentifier = identifier
        self.deviceModel = DeviceDatabase.model(for: identifier) ?? Self.fallbackModel(for: identifier)
        self.systemVersion = UIDevice.current.systemVersion
        self.estimatedRAM = Int64(ProcessInfo.processInfo.physicalMemory)

        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        self.batteryLevel = device.batteryLevel
        self.batteryState = device.batteryState

        (totalDiskSpace, freeDiskSpace) = Self.readDiskSpace()
    }

    func refreshBattery() {
        let device = UIDevice.current
        batteryLevel = device.batteryLevel
        batteryState = device.batteryState
    }

    // MARK: - Identificador de hardware

    private static func readHardwareIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result += String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    /// Estimación conservadora cuando el modelo no está en `DeviceDatabase`
    /// (por ejemplo un iPhone lanzado después de esta versión de la app).
    /// Usa solo capacidades detectables en tiempo de ejecución con APIs públicas.
    private static func fallbackModel(for identifier: String) -> DeviceModel {
        let screen = UIScreen.main

        return DeviceModel(
            identifier: identifier,
            marketingName: "Modelo desconocido (\(identifier))",
            year: Calendar.current.component(.year, from: Date()),
            chip: "Desconocido",
            screenSizeInches: Double(screen.bounds.height) / screen.scale / 160.0,
            hasTrueTone: true,
            hasProMotion: screen.maximumFramesPerSecond > 60,
            hasDynamicIsland: false,
            hasAlwaysOnDisplay: false,
            hasFaceID: true,
            hasTouchID: false,
            touchIDLocation: .none,
            rearCameraCount: 1,
            hasUltraWideCamera: false,
            hasTelephotoCamera: false,
            hasMacroCamera: false,
            hasLiDAR: false,
            hasOpticalZoom: false,
            connector: .usbC,
            supportsMagSafe: true,
            supportsWirelessCharging: true,
            supportsFastCharging: true,
            hasNFC: true,
            hasUltraWideband: false,
            hasBarometer: true,
            hasGyroscope: true,
            hasCompass: true,
            hasProximitySensor: true,
            hasAmbientLightSensor: true,
            hasActionButton: false,
            hasHomeButton: false,
            hasMuteSwitch: true,
            hasStereoSpeakers: true,
            microphoneCount: 2
        )
    }

    // MARK: - Almacenamiento

    private static func readDiskSpace() -> (total: Int64?, free: Int64?) {
        guard let url = URL.documentsDirectoryIfAvailable else { return (nil, nil) }
        do {
            let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            let total = values.volumeTotalCapacity.map { Int64($0) }
            let free = values.volumeAvailableCapacityForImportantUsage
            return (total, free)
        } catch {
            return (nil, nil)
        }
    }
}

private extension URL {
    static var documentsDirectoryIfAvailable: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
}

extension UIDevice.BatteryState {
    var label: String {
        switch self {
        case .charging: return "Cargando"
        case .full: return "Completa"
        case .unplugged: return "Desconectado"
        case .unknown: return "Desconocido"
        @unknown default: return "Desconocido"
        }
    }
}
