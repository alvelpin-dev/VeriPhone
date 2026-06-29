import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    let deviceInfo: DeviceInfoManager
    @Published var didStartDiagnostic = false

    init(deviceInfo: DeviceInfoManager = DeviceInfoManager()) {
        self.deviceInfo = deviceInfo
    }

    func makeDiagnosticViewModel() -> DiagnosticViewModel {
        DiagnosticViewModel(device: deviceInfo.deviceModel)
    }

    var capacityDescription: String {
        guard let total = deviceInfo.totalDiskSpace else { return "Desconocida" }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    var freeSpaceDescription: String {
        guard let free = deviceInfo.freeDiskSpace else { return "Desconocido" }
        return ByteCountFormatter.string(fromByteCount: free, countStyle: .file)
    }

    var ramDescription: String {
        ByteCountFormatter.string(fromByteCount: deviceInfo.estimatedRAM, countStyle: .memory)
    }

    var batteryPercentageDescription: String {
        guard deviceInfo.batteryLevel >= 0 else { return "Desconocido" }
        return "\(Int(deviceInfo.batteryLevel * 100))%"
    }
}
