import SwiftUI

struct ChargingTestContent: View {
    let device: DeviceModel
    let onComplete: TestCompletion

    @StateObject private var deviceInfo = DeviceInfoManager()
    @State private var observedCharging = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: deviceInfo.batteryState == .charging || deviceInfo.batteryState == .full ? "bolt.fill" : "bolt.slash")
                .font(.system(size: 48))
                .foregroundStyle(deviceInfo.batteryState == .charging ? .green : .secondary)

            Text(deviceInfo.batteryState.label)
                .font(.headline)

            Text("Conecta el cable\(device.connector == .usbC ? " USB-C" : " Lightning")\(device.supportsWirelessCharging ? " o un cargador inalámbrico/MagSafe" : "") y comprueba que el estado cambia a \"Cargando\".")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Comprobar estado de carga") {
                deviceInfo.refreshBattery()
                if deviceInfo.batteryState == .charging || deviceInfo.batteryState == .full {
                    observedCharging = true
                    onComplete(.pass, "El sistema confirma que el dispositivo está cargando o con carga completa.")
                } else {
                    onComplete(.warning, "El sistema no detecta carga en este momento. Conecta el cargador y vuelve a comprobar.")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear { deviceInfo.refreshBattery() }
    }
}
