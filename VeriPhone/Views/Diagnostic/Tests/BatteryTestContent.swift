import SwiftUI

struct BatteryTestContent: View {
    let device: DeviceModel
    let onComplete: TestCompletion

    @StateObject private var deviceInfo = DeviceInfoManager()
    @State private var hasEvaluated = false

    var body: some View {
        VStack(spacing: 16) {
            Gauge(value: Double(max(deviceInfo.batteryLevel, 0)), in: 0...1) {
                Text("Batería")
            } currentValueLabel: {
                Text("\(Int(deviceInfo.batteryLevel * 100))%")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(gaugeColor)
            .scaleEffect(1.6)
            .padding(.vertical, 12)

            Text(deviceInfo.batteryState.label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Evaluar batería") {
                evaluate()
            }
            .buttonStyle(.borderedProminent)
            .disabled(hasEvaluated)
        }
        .onAppear { deviceInfo.refreshBattery() }
    }

    private var gaugeColor: Color {
        switch deviceInfo.batteryLevel {
        case ..<0.2: return .red
        case ..<0.5: return .orange
        default: return .green
        }
    }

    private func evaluate() {
        hasEvaluated = true
        let level = deviceInfo.batteryLevel
        if level < 0 {
            onComplete(.warning, "No se pudo leer el nivel de batería en este momento.")
        } else if level < 0.15 && deviceInfo.batteryState == .unplugged {
            onComplete(.warning, "Nivel de batería bajo (\(Int(level * 100))%). Conecta el cargador para una evaluación más completa.")
        } else {
            onComplete(.pass, "Nivel de batería: \(Int(level * 100))%. Estado: \(deviceInfo.batteryState.label). Recuerda revisar la capacidad máxima en Ajustes > Batería, dato que iOS no expone a apps de terceros.")
        }
    }
}
