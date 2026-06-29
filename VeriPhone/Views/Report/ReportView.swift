import SwiftUI
import Charts

struct ReportView: View {
    @ObservedObject var viewModel: DiagnosticViewModel
    @State private var pdfURL: URL?
    @State private var isExporting = false

    var body: some View {
        ScrollView {
            ReportContent(viewModel: viewModel)
                .padding()
        }
        .navigationTitle("Informe final")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    export()
                } label: {
                    if isExporting {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(item: Binding(get: { pdfURL.map(IdentifiableURL.init) }, set: { pdfURL = $0?.url })) { wrapped in
            ShareSheet(items: [wrapped.url])
        }
    }

    private func export() {
        isExporting = true
        pdfURL = PDFExporter.renderPDF(from: ReportContent(viewModel: viewModel).padding())
        isExporting = false
    }
}

private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private struct ReportContent: View {
    @ObservedObject var viewModel: DiagnosticViewModel

    var body: some View {
        VStack(spacing: 24) {
            scoreHeader

            chart

            ForEach(DiagnosticCategory.allCases, id: \.self) { category in
                let tests = viewModel.tests(in: category)
                if !tests.isEmpty {
                    CategorySummaryRow(category: category, tests: tests, viewModel: viewModel)
                }
            }

            if !viewModel.failingResults.isEmpty {
                issuesSummary
            }
        }
    }

    private var scoreHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 14)
                Circle()
                    .trim(from: 0, to: viewModel.overallScore)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.snappy, value: viewModel.overallScore)
                Text("\(viewModel.overallScorePercentage)%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            }
            .frame(width: 160, height: 160)

            Text(verdict)
                .font(.headline)
                .foregroundStyle(scoreColor)
        }
    }

    private var scoreColor: Color {
        switch viewModel.overallScorePercentage {
        case 90...100: return .green
        case 70..<90: return .orange
        default: return .red
        }
    }

    private var verdict: String {
        switch viewModel.overallScorePercentage {
        case 95...100: return "Hardware en excelente estado"
        case 80..<95: return "Hardware en buen estado, con pequeños detalles"
        case 50..<80: return "Hardware con varios problemas detectados"
        default: return "Hardware con problemas significativos"
        }
    }

    private var chart: some View {
        Chart {
            ForEach(statusCounts, id: \.status.rawValue) { entry in
                SectorMark(angle: .value("Pruebas", entry.count), innerRadius: .ratio(0.6))
                    .foregroundStyle(entry.status.color)
            }
        }
        .frame(height: 200)
    }

    private var statusCounts: [(status: TestStatus, count: Int)] {
        let statuses: [TestStatus] = [.pass, .warning, .fail, .skipped]
        return statuses.compactMap { status in
            let count = viewModel.tests.filter { viewModel.result(for: $0).status == status }.count
            return count > 0 ? (status, count) : nil
        }
    }

    private var issuesSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Problemas detectados")
                .font(.headline)
            ForEach(viewModel.failingResults, id: \.0.id) { test, result in
                HStack(alignment: .top) {
                    StatusBadge(status: result.status, compact: true)
                    VStack(alignment: .leading) {
                        Text(test.title).font(.subheadline.weight(.medium))
                        Text(result.message).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct CategorySummaryRow: View {
    let category: DiagnosticCategory
    let tests: [DiagnosticTest]
    @ObservedObject var viewModel: DiagnosticViewModel

    private var passCount: Int { tests.filter { viewModel.result(for: $0).status == .pass }.count }
    private var ratio: Double { tests.isEmpty ? 0 : Double(passCount) / Double(tests.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(category.rawValue, systemImage: category.icon)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(passCount)/\(tests.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: ratio)
                .tint(ratio == 1 ? .green : .accentColor)
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
