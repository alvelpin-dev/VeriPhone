import CoreHaptics
import UIKit

/// Genera distintos patrones hápticos para que el usuario confirme manualmente
/// que el motor de vibración (Taptic Engine) funciona correctamente.
@MainActor
final class HapticManager: ObservableObject {

    @Published var isEngineAvailable: Bool = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    @Published var errorMessage: String?

    private var engine: CHHapticEngine?

    func prepareEngine() {
        guard isEngineAvailable else { return }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func playSharpTap() {
        playPattern(intensity: 1.0, sharpness: 1.0, duration: 0.1)
    }

    func playSoftThud() {
        playPattern(intensity: 0.6, sharpness: 0.1, duration: 0.3)
    }

    func playDoubleTap() {
        guard isEngineAvailable, let engine else {
            fallbackFeedback()
            return
        }
        do {
            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ], relativeTime: 0)
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ], relativeTime: 0.15)
            let pattern = try CHHapticPattern(events: [event1, event2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            errorMessage = error.localizedDescription
            fallbackFeedback()
        }
    }

    private func playPattern(intensity: Float, sharpness: Float, duration: TimeInterval) {
        guard isEngineAvailable, let engine else {
            fallbackFeedback()
            return
        }
        do {
            let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ], relativeTime: 0, duration: duration)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            errorMessage = error.localizedDescription
            fallbackFeedback()
        }
    }

    /// En dispositivos sin Core Haptics (p.ej. iPhone 6s con Taptic Engine de
    /// primera generación) se recurre a `UIImpactFeedbackGenerator`, que sigue
    /// activando el motor háptico aunque con menos control sobre el patrón.
    private func fallbackFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    func stop() {
        engine?.stop()
    }
}
