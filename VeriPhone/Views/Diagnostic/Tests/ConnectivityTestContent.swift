import SwiftUI
import CoreNFC

struct BluetoothTestContent: View {
    let onComplete: TestCompletion
    @StateObject private var connectivity = ConnectivityManager()

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(connectivity.bluetoothState == .poweredOn ? .blue : .secondary)
            Text(connectivity.bluetoothState.label)
                .font(.headline)

            Button("Confirmar resultado") {
                switch connectivity.bluetoothState {
                case .poweredOn:
                    onComplete(.pass, "Bluetooth activo y operativo.")
                case .poweredOff:
                    onComplete(.warning, "Bluetooth desactivado. Actívalo en Ajustes para confirmar el hardware.")
                case .unsupported:
                    onComplete(.fail, "Bluetooth no soportado.")
                default:
                    onComplete(.warning, "Estado de Bluetooth no concluyente: \(connectivity.bluetoothState.label).")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear { connectivity.startMonitoringBluetooth() }
    }
}

struct NetworkTestContent: View {
    let kind: DiagnosticTestKind
    let onComplete: TestCompletion
    @StateObject private var connectivity = ConnectivityManager()

    private var isWiFi: Bool { kind == .wifi }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isWiFi ? "wifi" : "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundStyle((isWiFi ? connectivity.isWiFiConnected : connectivity.isCellularConnected) ? .blue : .secondary)
            Text((isWiFi ? connectivity.isWiFiConnected : connectivity.isCellularConnected) ? "Conectado" : "Sin conexión activa")
                .font(.headline)

            Button("Confirmar resultado") {
                let connected = isWiFi ? connectivity.isWiFiConnected : connectivity.isCellularConnected
                if connected {
                    onComplete(.pass, isWiFi ? "Conexión Wi-Fi activa." : "Conexión de datos móviles activa.")
                } else {
                    onComplete(.warning, isWiFi ? "No hay conexión Wi-Fi activa en este momento." : "No hay conexión de datos móviles activa en este momento.")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear { connectivity.startMonitoringNetwork() }
        .onDisappear { connectivity.stopMonitoringNetwork() }
    }
}

struct NFCTestContent: View {
    let onComplete: TestCompletion

    private var isAvailable: Bool { NFCNDEFReaderSession.readingAvailable }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wave.3.forward.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(isAvailable ? .blue : .secondary)
            Text(isAvailable ? "Lectura NFC disponible" : "NFC no disponible")
                .font(.headline)

            Button("Confirmar resultado") {
                if isAvailable {
                    onComplete(.pass, "El sistema reporta capacidad de lectura NFC.")
                } else {
                    onComplete(.fail, "El sistema no reporta capacidad de lectura NFC.")
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
