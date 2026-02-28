import SwiftUI
import SaphanCore

struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var subscriptionViewModel: SubscriptionViewModel
    @State private var isLoading = true
    @State private var hasStartedInitialBoot = false
    @State private var hasLoadedSubscriptionState = false
    @State private var hasCompletedOnboarding = PreferencesService.shared.hasCompletedOnboarding

    private enum Route: Equatable {
        case splash
        case auth
        case onboarding
        case paywall
        case main
    }

    private var route: Route {
        if isLoading || authViewModel.isLoading {
            return .splash
        }

        // 1. Onboarding first — before auth
        if !hasCompletedOnboarding {
            return .onboarding
        }

        // 2. Then auth
        guard authViewModel.isAuthenticated else {
            return .auth
        }

        // 3. Wait for subscription check
        if !hasLoadedSubscriptionState {
            return .splash
        }

        // 4. Hard paywall
        if !subscriptionViewModel.isSubscribed {
            return .paywall
        }

        return .main
    }

    private var splashStatusText: String? {
        if isLoading || authViewModel.isLoading {
            return "Preparing app..."
        }

        if authViewModel.isAuthenticated && !hasLoadedSubscriptionState {
            return "Checking subscription..."
        }

        return nil
    }

    var body: some View {
        ZStack {
            if route == .splash {
                SplashView(statusText: splashStatusText)
                    .transition(.opacity)
            } else if route == .auth {
                AuthContainerView()
                    .transition(.opacity.combined(with: .scale(scale: 1.01)))
            } else if route == .onboarding {
                OnboardingContainerView {
                    PreferencesService.shared.hasCompletedOnboarding = true
                    withAnimation(SaphanMotion.smoothSpring) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if route == .paywall {
                PaywallView(mode: .required)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(SaphanMotion.smoothSpring, value: route)
        .onAppear {
            guard !hasStartedInitialBoot else { return }
            hasStartedInitialBoot = true

            hasCompletedOnboarding = PreferencesService.shared.hasCompletedOnboarding

            Task {
                await refreshSubscriptionStateIfNeeded()
            }

            Task {
                try? await Task.sleep(nanoseconds: 1_100_000_000)
                withAnimation(SaphanMotion.smoothSpring) {
                    isLoading = false
                }
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            Task {
                if isAuthenticated {
                    await refreshSubscriptionStateIfNeeded(forceRefresh: true)
                } else {
                    hasLoadedSubscriptionState = false
                    await subscriptionViewModel.syncForAuthenticatedUser(nil)
                }
            }
        }
        .onChange(of: authViewModel.currentUser?.id) { userID in
            guard authViewModel.isAuthenticated else { return }
            Task {
                await refreshSubscriptionStateIfNeeded(
                    forceRefresh: true,
                    userIDOverride: userID
                )
            }
        }
    }

    private func refreshSubscriptionStateIfNeeded(
        forceRefresh: Bool = false,
        userIDOverride: String? = nil
    ) async {
        guard authViewModel.isAuthenticated else {
            hasLoadedSubscriptionState = false
            return
        }

        if !forceRefresh && hasLoadedSubscriptionState {
            return
        }

        hasLoadedSubscriptionState = false
        let userID = userIDOverride ?? authViewModel.currentUser?.id
        await subscriptionViewModel.syncForAuthenticatedUser(userID)
        hasLoadedSubscriptionState = true
    }
}

struct SplashView: View {
    let statusText: String?
    @State private var animate = false

    var body: some View {
        ZStack {
            Color(red: 44/255, green: 44/255, blue: 46/255)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SaphanTheme.brandCoral, Color(red: 193/255, green: 162/255, blue: 139/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animate ? 1.02 : 0.97)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)

                Text("Saphan")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .padding(.top, 8)

                if let statusText, !statusText.isEmpty {
                    Text(statusText)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthViewModel())
        .environmentObject(NetworkMonitor.shared)
        .environmentObject(SubscriptionViewModel())
}
