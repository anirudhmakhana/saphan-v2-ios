import SwiftUI
import SaphanCore

struct OnboardingContainerView: View {
    @State private var currentPage = 0
    let onCompleted: (() -> Void)?

    private let totalPages = 4

    init(onCompleted: (() -> Void)? = nil) {
        self.onCompleted = onCompleted
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    if currentPage < totalPages - 1 {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        icon: "figure.2.and.child.holdinghands",
                        iconGradient: [.blue, .purple],
                        title: "Welcome to Saphan",
                        description: "Translate feelings, not just words.\n\nConnect with people across languages and cultures with context-aware translation."
                    )
                    .tag(0)

                    OnboardingPageView(
                        icon: "waveform",
                        iconGradient: [.blue, .cyan],
                        title: "Real-Time Voice Translation",
                        description: "Speak naturally and hear translations instantly in 16 languages.\n\nChoose the context that fits your conversation."
                    )
                    .tag(1)

                    OnboardingPageView(
                        icon: "keyboard",
                        iconGradient: [.purple, .pink],
                        title: "Smart Translation Keyboard",
                        description: "Type in any app and translate with the perfect tone.\n\nFrom casual chats to professional emails."
                    )
                    .tag(2)

                    OnboardingPageView(
                        icon: "checkmark.circle.fill",
                        iconGradient: [.green, .blue],
                        title: "You're All Set!",
                        description: "To use the translation keyboard, enable it in Settings > General > Keyboard > Keyboards > Add New Keyboard > Saphan.",
                        showContinueButton: true,
                        onContinue: completeOnboarding
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: 24) {
                    PageIndicator(currentPage: currentPage, totalPages: totalPages)

                    if currentPage < totalPages - 1 {
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }

    private func completeOnboarding() {
        onCompleted?()
    }
}

struct OnboardingPageView: View {
    let icon: String
    let iconGradient: [Color]
    let title: String
    let description: String
    var showContinueButton: Bool = false
    var onContinue: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 48) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: iconGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 60)

            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            if showContinueButton, let onContinue = onContinue {
                Button {
                    onContinue()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
            }

            Spacer()
        }
    }
}

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.blue : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentPage)
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
}
