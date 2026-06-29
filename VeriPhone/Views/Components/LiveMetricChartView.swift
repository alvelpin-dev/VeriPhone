import SwiftUI
import Charts

/// Gráfico de línea en vivo reutilizable para acelerómetro, giroscopio,
/// barómetro, etc. Mantiene una ventana deslizante de muestras.
struct LiveMetricSample: Identifiable {
    let id = UUID()
    let time: Double
    let value: Double
    let axis: String
}

struct LiveMetricChartView: View {
    let title: String
    let unit: String
    let samples: [LiveMetricSample]
    let axisColors: [String: Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Chart(samples) { sample in
                LineMark(
                    x: .value("Tiempo", sample.time),
                    y: .value(unit, sample.value)
                )
                .foregroundStyle(by: .value("Eje", sample.axis))
                .interpolationMethod(.catmullRom)
            }
            .chartForegroundStyleScale(domain: Array(axisColors.keys.sorted()), range: Array(axisColors.keys.sorted().map { axisColors[$0] ?? .accentColor }))
            .chartXAxis(.hidden)
            .frame(height: 180)
            .animation(.linear(duration: 0.1), value: samples.count)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}
