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
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingContainerView {
                    PreferencesService.shared.hasCompletedOnboarding = true
                    withAnimation(SaphanMotion.smoothSpring) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if !authViewModel.isAuthenticated {
                AuthContainerView()
                    .transition(.opacity.combined(with: .scale(scale: 1.01)))
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(SaphanMotion.smoothSpring, value: isLoading)
        .animation(SaphanMotion.smoothSpring, value: hasCompletedOnboarding)
        .animation(SaphanMotion.smoothSpring, value: authViewModel.isAuthenticated)
        .onAppear {
            hasCompletedOnboarding = PreferencesService.shared.hasCompletedOnboarding
            Task {
                try? await Task.sleep(nanoseconds: 1_100_000_000)
                withAnimation(SaphanMotion.smoothSpring) {
                    isLoading = false
                }
            }
        }
    }
}

struct SplashView: View {
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
}
