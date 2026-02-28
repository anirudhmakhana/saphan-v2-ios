import SwiftUI
import SaphanCore

@main
struct SaphanApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(SaphanTheme.brandCoral)
                .environmentObject(authViewModel)
                .environmentObject(networkMonitor)
                .environmentObject(subscriptionViewModel)
                .task {
                    await subscriptionViewModel.syncForAuthenticatedUser(
                        authViewModel.isAuthenticated ? authViewModel.currentUser?.id : nil
                    )
                }
                .onChange(of: authViewModel.currentUser?.id) { userID in
                    Task {
                        await subscriptionViewModel.syncForAuthenticatedUser(
                            authViewModel.isAuthenticated ? userID : nil
                        )
                    }
                }
                .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
                    Task {
                        await subscriptionViewModel.syncForAuthenticatedUser(
                            isAuthenticated ? authViewModel.currentUser?.id : nil
                        )
                    }
                }
        }
    }
}
