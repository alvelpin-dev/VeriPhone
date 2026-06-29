import SwiftUI

/// Firma común que usan todas las vistas de contenido de prueba para
/// reportar su resultado al `DiagnosticViewModel`.
typealias TestCompletion = (TestStatus, String) -> Void

/// Vista de detalle genérica: muestra cabecera, nota de limitación (si
/// existe) y delega el contenido específico según `test.kind`.
struct TestDetailView: View {
    @ObservedObject var viewModel: DiagnosticViewModel
    let test: DiagnosticTest
    @Environment(\.dismiss) private var dismiss

    private var result: TestResult { viewModel.result(for: test) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                contentView

                if result.status != .pending {
                    VStack(spacing: 8) {
                        StatusBadge(status: result.status)
                        if !result.message.isEmpty {
                            Text(result.message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        if test.isAutomatic && result.status == .pass {
                            Text("Volviendo a la lista…")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                }

                if let note = test.limitationNote {
                    LimitationNoteView(text: note)
                }
            }
            .padding()
        }
        .navigationTitle(test.title)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.snappy, value: result.status)
        // Las pruebas automáticas se confirman solas: en cuanto el sistema
        // detecta que el hardware funciona, no tiene sentido obligar al
        // usuario a pulsar "atrás" manualmente.
        .onChange(of: result.status) { _, newStatus in
            guard test.isAutomatic, newStatus == .pass else { return }
            Task {
                try? await Task.sleep(for: .seconds(1.1))
                guard !Task.isCancelled else { return }
                dismiss()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: test.category.icon)
                .font(.system(size: 40))
                .foregroundStyle(.tint)
            Text(test.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        let onComplete: TestCompletion = { status, message in
            viewModel.record(status: status, message: message, for: test)
        }

        switch test.kind {
        case .battery:
            BatteryTestContent(device: viewModel.device, onComplete: onComplete)
        case .display:
            DisplayRefreshTestContent(device: viewModel.device, onComplete: onComplete)
        case .colorPattern:
            ColorPatternTestContent(onComplete: onComplete)
        case .multitouch:
            MultitouchTestContent(onComplete: onComplete)
        case .faceID, .touchID:
            BiometricTestContent(kind: test.kind, onComplete: onComplete)
        case .rearCamera:
            CameraTestContent(position: .back, device: viewModel.device, onComplete: onComplete)
        case .frontCamera:
            CameraTestContent(position: .front, device: viewModel.device, onComplete: onComplete)
        case .microphone:
            MicrophoneTestContent(onComplete: onComplete)
        case .speakers:
            SpeakerTestContent(device: viewModel.device, onComplete: onComplete)
        case .buttons:
            ButtonsTestContent(device: viewModel.device, onComplete: onComplete)
        case .haptics:
            HapticsTestContent(onComplete: onComplete)
        case .accelerometer:
            AccelerometerTestContent(onComplete: onComplete)
        case .gyroscope:
            GyroscopeTestContent(onComplete: onComplete)
        case .compass:
            CompassTestContent(onComplete: onComplete)
        case .gps:
            GPSTestContent(onComplete: onComplete)
        case .bluetooth:
            BluetoothTestContent(onComplete: onComplete)
        case .wifi, .cellular:
            NetworkTestContent(kind: test.kind, onComplete: onComplete)
        case .nfc:
            NFCTestContent(onComplete: onComplete)
        case .charging:
            ChargingTestContent(device: viewModel.device, onComplete: onComplete)
        case .proximity:
            ProximityTestContent(onComplete: onComplete)
        case .ambientLight:
            AmbientLightTestContent(onComplete: onComplete)
        case .lidar:
            LiDARTestContent(onComplete: onComplete)
        case .barometer:
            BarometerTestContent(onComplete: onComplete)
        case .dynamicIsland:
            DynamicIslandTestContent(onComplete: onComplete)
        case .alwaysOnDisplay:
            AlwaysOnDisplayTestContent(device: viewModel.device, onComplete: onComplete)
        }
    }
}

struct LimitationNoteView: View {
    let text: String
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 6)
        } label: {
            Label("Limitación de API pública", systemImage: "info.circle")
                .font(.footnote.weight(.medium))
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}
