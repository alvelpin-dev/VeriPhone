import Network
import CoreBluetooth
import CoreNFC
import Combine

/// Estado de Wi-Fi / datos móviles mediante `NWPathMonitor`, y estado de
/// Bluetooth mediante `CBCentralManager`.
///
/// Limitación: iOS no permite leer la intensidad de señal Wi-Fi ni el
/// operador de datos móviles desde una app de terceros sin entitlements
/// privados; solo se puede confirmar si hay una interfaz activa de cada tipo.
@MainActor
final class ConnectivityManager: NSObject, ObservableObject {

    @Published var isWiFiConnected = false
    @Published var isCellularConnected = false
    @Published var isAnyConnectionAvailable = false
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var isNFCReadingAvailable: Bool = NFCNDEFReaderSession.readingAvailable

    private var pathMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.veriphone.pathmonitor")
    private var bluetoothManager: CBCentralManager?

    func startMonitoringNetwork() {
        let monitor = NWPathMonitor()
        pathMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                self.isWiFiConnected = path.usesInterfaceType(.wifi)
                self.isCellularConnected = path.usesInterfaceType(.cellular)
                self.isAnyConnectionAvailable = path.status == .satisfied
            }
        }
        monitor.start(queue: monitorQueue)
    }

    func stopMonitoringNetwork() {
        pathMonitor?.cancel()
        pathMonitor = nil
    }

    func startMonitoringBluetooth() {
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension ConnectivityManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        Task { @MainActor in self.bluetoothState = state }
    }
}

extension CBManagerState {
    var label: String {
        switch self {
        case .poweredOn: return "Activado"
        case .poweredOff: return "Desactivado"
        case .unauthorized: return "Sin autorización"
        case .unsupported: return "No compatible"
        case .resetting: return "Reiniciando"
        case .unknown: return "Desconocido"
        @unknown default: return "Desconocido"
        }
    }
}
