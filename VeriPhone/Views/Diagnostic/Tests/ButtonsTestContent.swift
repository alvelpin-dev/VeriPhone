import SwiftUI
import AVFoundation
import Combine

/// El volumen del sistema es la única pulsación de botón física observable
/// mediante una API pública (KVO sobre `outputVolume` de `AVAudioSession`).
/// El resto de botones (lateral, Acción, Home, silencio) no son detectables
/// por software de terceros, así que se confirman manualmente.
@MainActor
private final class VolumeButtonObserver: NSObject, ObservableObject {
    @Published var volumeChanged = false
    private var cancellable: AnyCancellable?
    private var initialVolume: Float = 0

    func start() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        initialVolume = session.outputVolume
        cancellable = session.publisher(for: \.outputVolume)
            .dropFirst()
            .sink { [weak self] _ in
                self?.volumeChanged = true
            }
    }

    func stop() {
        cancellable?.cancel()
    }
}

struct ButtonsTestContent: View {
    let device: DeviceModel
    let onComplete: TestCompletion

    @StateObject private var volumeObserver = VolumeButtonObserver()
    @State private var sideButtonConfirmed: Bool?
    @State private var actionButtonConfirmed: Bool?
    @State private var homeButtonConfirmed: Bool?
    @State private var muteSwitchConfirmed: Bool?

    var body: some View {
        VStack(spacing: 16) {
            Label(volumeObserver.volumeChanged ? "Volumen detectado correctamente" : "Pulsa Volumen + o Volumen − ahora",
                  systemImage: volumeObserver.volumeChanged ? "checkmark.circle.fill" : "speaker.wave.2")
                .foregroundStyle(volumeObserver.volumeChanged ? .green : .secondary)

            Divider()

            ConfirmRow(title: "Botón lateral", confirmed: $sideButtonConfirmed)
            if device.hasActionButton {
                ConfirmRow(title: "Botón de Acción", confirmed: $actionButtonConfirmed)
            }
            if device.hasHomeButton {
                ConfirmRow(title: "Botón Home", confirmed: $homeButtonConfirmed)
            }
            if device.hasMuteSwitch {
                ConfirmRow(title: "Interruptor de silencio", confirmed: $muteSwitchConfirmed)
            }

            Button("Finalizar prueba de botones") {
                finish()
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear { volumeObserver.start() }
        .onDisappear { volumeObserver.stop() }
    }

    private func finish() {
        var relevant = [sideButtonConfirmed]
        if device.hasActionButton { relevant.append(actionButtonConfirmed) }
        if device.hasHomeButton { relevant.append(homeButtonConfirmed) }
        if device.hasMuteSwitch { relevant.append(muteSwitchConfirmed) }

        let allConfirmed = volumeObserver.volumeChanged && relevant.allSatisfy { $0 == true }
        let anyFailed = relevant.contains(false) || !volumeObserver.volumeChanged

        if allConfirmed {
            onComplete(.pass, "Todos los botones físicos respondieron correctamente.")
        } else if anyFailed && relevant.contains(where: { $0 != nil }) {
            onComplete(.fail, "Alguno de los botones físicos no respondió correctamente.")
        } else {
            onComplete(.warning, "Confirma todos los botones antes de finalizar la prueba.")
        }
    }
}

private struct ConfirmRow: View {
    let title: String
    @Binding var confirmed: Bool?

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Button("Sí") { confirmed = true }
                .buttonStyle(.bordered)
                .tint(confirmed == true ? .green : .gray)
            Button("No") { confirmed = false }
                .buttonStyle(.bordered)
                .tint(confirmed == false ? .red : .gray)
        }
    }
}
