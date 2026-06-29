import SwiftUI

@main
struct VeriPhoneApp: App {

    @StateObject private var homeViewModel = HomeViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView(viewModel: homeViewModel)
            }
            .preferredColorScheme(nil) // respeta el modo claro/oscuro del sistema
        }
    }
}
