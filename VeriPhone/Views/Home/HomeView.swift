import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showDiagnostic = false

    var body: some View {
        List {
            DeviceInfoCard(viewModel: viewModel)

            Section {
                Button {
                    showDiagnostic = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Iniciar diagnóstico", systemImage: "stethoscope")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("VeriPhone")
        .navigationDestination(isPresented: $showDiagnostic) {
            DiagnosticListView(viewModel: viewModel.makeDiagnosticViewModel())
        }
        .onAppear { viewModel.deviceInfo.refreshBattery() }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel())
    }
}
