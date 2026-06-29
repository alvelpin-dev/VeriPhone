import AVFoundation

/// Gestiona grabación de micrófono, reproducción de tonos y enrutado de salida
/// de audio (auricular / altavoz) para las pruebas de audio.
@MainActor
final class AudioManager: NSObject, ObservableObject {

    @Published var inputLevel: Float = 0       // 0...1
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var availableInputs: [String] = []
    @Published var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var levelTimer: Timer?
    private let toneEngine = AVAudioEngine()
    private var tonePlayerNode: AVAudioPlayerNode?

    func requestMicrophoneAccess() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func refreshAvailableInputs() {
        availableInputs = AVAudioSession.sharedInstance().availableInputs?.map(\.portName) ?? []
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory.appendingPathComponent("veriphone_mic_test.caf")
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatAppleLossless,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1
            ]
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            isRecording = true

            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self, let recorder = self.recorder else { return }
                    recorder.updateMeters()
                    let power = recorder.averagePower(forChannel: 0)
                    let normalized = max(0, min(1, (power + 60) / 60))
                    self.inputLevel = normalized
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording() -> URL? {
        recorder?.stop()
        levelTimer?.invalidate()
        levelTimer = nil
        isRecording = false
        return recorder?.url
    }

    func playRecording(from url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            isPlaying = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Reproduce un tono de prueba forzando la salida a un puerto concreto
    /// (auricular vs. altavoz inferior) usando `overrideOutputAudioPort`.
    func playTestTone(throughSpeaker: Bool) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: throughSpeaker ? [.defaultToSpeaker] : [])
            try session.overrideOutputAudioPort(throughSpeaker ? .speaker : .none)
            try session.setActive(true)

            guard let url = Bundle.main.url(forResource: "test_tone", withExtension: "caf") else {
                generateAndPlayBeep()
                return
            }
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            isPlaying = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Genera y reproduce un tono sintético de 880 Hz mediante `AVAudioEngine`
    /// (no requiere ningún recurso de audio empaquetado en la app).
    private func generateAndPlayBeep() {
        let sampleRate = 44100.0
        let duration = 0.6
        let frequency = 880.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let channel = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            channel[i] = Float(sin(2.0 * .pi * frequency * Double(i) / sampleRate)) * 0.5
        }

        let node = AVAudioPlayerNode()
        toneEngine.attach(node)
        toneEngine.connect(node, to: toneEngine.mainMixerNode, format: format)
        tonePlayerNode = node

        do {
            try toneEngine.start()
            isPlaying = true
            node.scheduleBuffer(buffer) { [weak self] in
                Task { @MainActor in self?.isPlaying = false }
            }
            node.play()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopPlayback() {
        player?.stop()
        tonePlayerNode?.stop()
        toneEngine.stop()
        isPlaying = false
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.isPlaying = false }
    }
}
