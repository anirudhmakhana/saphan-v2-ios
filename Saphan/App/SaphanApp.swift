import SwiftUI
import SaphanCore

@main
struct SaphanApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(SaphanTheme.brandCoral)
                .environmentObject(authViewModel)
                .environmentObject(networkMonitor)
        }
    }
}
