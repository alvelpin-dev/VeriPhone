import SwiftUI

// MARK: - Micrófono

struct MicrophoneTestContent: View {
    let onComplete: TestCompletion

    @StateObject private var audio = AudioManager()
    @State private var recordedURL: URL?
    @State private var hasGrantedAccess = false

    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(audio.inputLevel))
                .progressViewStyle(.linear)
                .tint(.blue)
                .frame(height: 8)

            Text(audio.isRecording ? "Grabando…" : "Pulsa para grabar unos segundos")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button {
                    if audio.isRecording {
                        recordedURL = audio.stopRecording()
                    } else {
                        audio.startRecording()
                    }
                } label: {
                    Label(audio.isRecording ? "Detener" : "Grabar", systemImage: audio.isRecording ? "stop.fill" : "mic.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(audio.isRecording ? .red : .accentColor)

                if let recordedURL {
                    Button {
                        audio.playRecording(from: recordedURL)
                    } label: {
                        Label("Reproducir", systemImage: "play.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(audio.isPlaying)
                }
            }

            Button("Finalizar prueba de micrófono") {
                finish()
            }
            .buttonStyle(.bordered)
        }
        .task {
            hasGrantedAccess = await audio.requestMicrophoneAccess()
            audio.refreshAvailableInputs()
        }
    }

    private func finish() {
        if let error = audio.errorMessage {
            onComplete(.fail, error)
        } else if !hasGrantedAccess {
            onComplete(.warning, "No se concedió permiso de micrófono.")
        } else if recordedURL != nil {
            onComplete(.pass, "Grabación y reproducción verificadas. Micrófonos detectados por el sistema: \(audio.availableInputs.joined(separator: ", "))")
        } else {
            onComplete(.warning, "No se realizó ninguna grabación durante la prueba.")
        }
    }
}

// MARK: - Altavoces

struct SpeakerTestContent: View {
    let device: DeviceModel
    let onComplete: TestCompletion

    @StateObject private var audio = AudioManager()
    @State private var testedReceiver = false
    @State private var testedSpeaker = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Reproduce un tono por cada salida y confirma si lo escuchas con claridad.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                audio.playTestTone(throughSpeaker: false)
                testedReceiver = true
            } label: {
                Label("Probar auricular", systemImage: "phone.fill")
            }
            .buttonStyle(.bordered)

            Button {
                audio.playTestTone(throughSpeaker: true)
                testedSpeaker = true
            } label: {
                Label(device.hasStereoSpeakers ? "Probar altavoces estéreo" : "Probar altavoz inferior", systemImage: "speaker.wave.3.fill")
            }
            .buttonStyle(.bordered)

            ManualConfirmView(
                icon: "ear",
                instruction: "Tras escuchar ambos tonos,",
                question: "¿Se reprodujo el sonido correctamente en todas las salidas?"
            ) { confirmed in
                if !testedReceiver || !testedSpeaker {
                    onComplete(.warning, "Confirma que probaste ambas salidas de audio antes de finalizar.")
                } else if confirmed {
                    onComplete(.pass, "El usuario confirmó audio correcto en auricular y altavoz.")
                } else {
                    onComplete(.fail, "El usuario reportó problemas de audio en alguna salida.")
                }
            }
        }
        .onDisappear { audio.stopPlayback() }
    }
}
