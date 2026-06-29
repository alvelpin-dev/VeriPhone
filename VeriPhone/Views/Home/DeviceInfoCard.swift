import SwiftUI

struct DeviceInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct DeviceInfoCard: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        Section {
            DeviceInfoRow(icon: "iphone", label: "Modelo", value: viewModel.deviceInfo.deviceModel.marketingName)
            DeviceInfoRow(icon: "gearshape", label: "Versión de iOS", value: viewModel.deviceInfo.systemVersion)
            DeviceInfoRow(icon: "cpu", label: "Chip", value: viewModel.deviceInfo.deviceModel.chip)
            DeviceInfoRow(icon: "memorychip", label: "RAM estimada", value: viewModel.ramDescription)
            DeviceInfoRow(icon: "internaldrive", label: "Capacidad", value: viewModel.capacityDescription)
            DeviceInfoRow(icon: "internaldrive.fill", label: "Espacio libre", value: viewModel.freeSpaceDescription)
            DeviceInfoRow(icon: "battery.100percent", label: "Batería", value: "\(viewModel.batteryPercentageDescription) · \(viewModel.deviceInfo.batteryState.label)")
        } header: {
            Text("Información del dispositivo")
        } footer: {
            Text("El número de serie real no es accesible mediante API pública de iOS por motivos de privacidad de Apple.")
        }
    }
}
