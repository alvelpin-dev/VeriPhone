import SwiftUI

struct HapticsTestContent: View {
    let onComplete: TestCompletion

    @StateObject private var haptics = HapticManager()

    var body: some View {
        VStack(spacing: 16) {
            if !haptics.isEngineAvailable {
                Text("Este dispositivo no dispone de Core Haptics; se usará retroalimentación táctil básica.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                Button("Vibración corta y nítida") { haptics.playSharpTap() }
                    .buttonStyle(.bordered)
                Button("Vibración suave y prolongada") { haptics.playSoftThud() }
                    .buttonStyle(.bordered)
                Button("Doble toque") { haptics.playDoubleTap() }
                    .buttonStyle(.bordered)
            }

            ManualConfirmView(
                icon: "iphone.radiowaves.left.and.right",
                instruction: "Tras probar los tres patrones,",
                question: "¿Notaste correctamente las vibraciones?"
            ) { confirmed in
                if confirmed {
                    onComplete(.pass, "El usuario confirmó que el motor háptico funciona correctamente.")
                } else {
                    onComplete(.fail, "El usuario reportó que no nota correctamente las vibraciones.")
                }
            }
        }
        .onAppear { haptics.prepareEngine() }
        .onDisappear { haptics.stop() }
    }
}
