import SwiftUI

/// Insignia visual reutilizable para mostrar un `TestStatus`.
struct StatusBadge: View {
    let status: TestStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.symbolName)
                .foregroundStyle(status.color)
            if !compact {
                Text(status.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(status.color)
            }
        }
        .padding(.horizontal, compact ? 0 : 10)
        .padding(.vertical, compact ? 0 : 4)
        .background(compact ? Color.clear : status.color.opacity(0.12))
        .clipShape(Capsule())
        .animation(.snappy, value: status)
    }
}

extension TestStatus: Equatable {}
