import SwiftUI

struct DiagnosticListView: View {
    @ObservedObject var viewModel: DiagnosticViewModel
    @State private var showReport = false

    private var presentCategories: [DiagnosticCategory] {
        DiagnosticCategory.allCases.filter { !viewModel.tests(in: $0).isEmpty }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progreso")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.completedCount)/\(viewModel.tests.count)")
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: viewModel.progress)
                        .tint(.accentColor)
                }
                .padding(.vertical, 4)
            }

            ForEach(presentCategories, id: \.self) { category in
                Section(category.rawValue) {
                    ForEach(viewModel.tests(in: category)) { test in
                        NavigationLink {
                            TestDetailView(viewModel: viewModel, test: test)
                        } label: {
                            HStack {
                                Image(systemName: category.icon)
                                    .frame(width: 28)
                                    .foregroundStyle(.tint)
                                VStack(alignment: .leading) {
                                    Text(test.title).font(.body)
                                    Text(test.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                StatusBadge(status: viewModel.result(for: test).status, compact: true)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    showReport = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Ver informe final", systemImage: "doc.text.magnifyingglass")
                            .font(.headline)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Diagnóstico")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showReport) {
            ReportView(viewModel: viewModel)
        }
    }
}
