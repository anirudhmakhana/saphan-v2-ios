import SwiftUI
import SaphanCore

struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var isLoading = true
    @State private var hasCompletedOnboarding = PreferencesService.shared.hasCompletedOnboarding

    var body: some View {
        ZStack {
            if isLoading {
                SplashView()
            } else if !hasCompletedOnboarding {
                OnboardingContainerView {
                    PreferencesService.shared.hasCompletedOnboarding = true
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }
            } else if !authViewModel.isAuthenticated {
                AuthContainerView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            hasCompletedOnboarding = PreferencesService.shared.hasCompletedOnboarding
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.15)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Saphan")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthViewModel())
        .environmentObject(NetworkMonitor.shared)
}
