import SwiftUI

/// Push-to-talk button with visual feedback
struct PTTButtonView: View {
    let isActive: Bool
    let isSpeaking: Bool
    let onPressDown: () -> Void
    let onPressUp: () -> Void

    @State private var isPressed = false
    @State private var pulse = false
    @Environment(\.colorScheme) private var colorScheme

    private var palette: VoiceTranslationTheme.Palette {
        VoiceTranslationTheme.palette(for: colorScheme)
    }

    private var signalColor: Color {
        if isActive { return palette.danger }
        if isSpeaking { return palette.warning }
        return palette.accent
    }

    private var iconName: String {
        if isActive { return "mic.fill" }
        if isSpeaking { return "waveform" }
        return "mic"
    }

    private var titleText: String {
        if isActive { return "Release to send" }
        if isSpeaking { return "Assistant speaking" }
        return "Hold to talk"
    }

    private var subtitleText: String {
        if isActive { return "You're live" }
        if isSpeaking { return "Listening resumes automatically" }
        return "Press and hold for instant translation"
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(signalColor.opacity(0.16))
                    .frame(width: 170, height: 170)
                    .scaleEffect(pulse ? 1.12 : 0.96)
                    .opacity((isActive || isSpeaking) ? 1 : 0)

                Circle()
                    .fill(signalColor.opacity(0.12))
                    .frame(width: 132, height: 132)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [signalColor.opacity(0.96), signalColor.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 112, height: 112)
                    .shadow(color: signalColor.opacity(0.35), radius: 18, y: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.22 : 0.45), lineWidth: 1)
                    )

                Image(systemName: iconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isPressed)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed, !isSpeaking else { return }
                        isPressed = true
                        onPressDown()
                    }
                    .onEnded { _ in
                        guard isPressed else { return }
                        isPressed = false
                        onPressUp()
                    }
            )
            .onAppear {
                pulse = true
            }
            .disabled(isSpeaking)

            VStack(spacing: 3) {
                Text(titleText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.primaryText)

                Text(subtitleText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 24) {
        PTTButtonView(isActive: false, isSpeaking: false, onPressDown: { }, onPressUp: { })
        PTTButtonView(isActive: true, isSpeaking: false, onPressDown: { }, onPressUp: { })
    }
    .padding()
}
