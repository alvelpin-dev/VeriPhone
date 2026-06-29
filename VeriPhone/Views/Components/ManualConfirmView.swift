import SwiftUI

/// Asistente reutilizable para pruebas que no pueden verificarse de forma
/// automática: presenta una pregunta y dos botones de respuesta (Sí/No),
/// devolviendo el resultado correspondiente.
struct ManualConfirmView: View {
    let icon: String
    let instruction: String
    let question: String
    var onAnswer: (Bool) -> Void

    @State private var answered: Bool?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, isActive: answered == nil)

            Text(instruction)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text(question)
                .font(.headline)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button {
                    answered = false
                    onAnswer(false)
                } label: {
                    Label("No", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button {
                    answered = true
                    onAnswer(true)
                } label: {
                    Label("Sí", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .disabled(answered != nil)
        }
        .padding(24)
    }
}
