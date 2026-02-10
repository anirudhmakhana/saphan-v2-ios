import SwiftUI

/// Push-to-talk button with visual feedback
struct PTTButtonView: View {
    let isActive: Bool
    let isProcessing: Bool
    let isSpeaking: Bool
    let onPressDown: () -> Void
    let onHoldConfirmed: () -> Void
    let onRelease: () -> Void
    let onCancel: () -> Void

    @State private var isPressed = false
    @State private var pulse = false
    @State private var isInsideTouchRegion = true
    @State private var hasTriggeredHold = false
    @State private var holdTask: Task<Void, Never>?
    @Environment(\.colorScheme) private var colorScheme

    private var palette: SaphanTheme.Palette {
        SaphanTheme.palette(for: colorScheme)
    }

    private let holdConfirmationThreshold: UInt64 = 120_000_000

    private var signalColor: Color {
        if isProcessing { return palette.warning }
        if isActive { return palette.danger }
        if isSpeaking { return palette.warning }
        return palette.accent
    }

    private var iconName: String {
        if isProcessing { return "hourglass" }
        if isActive { return "mic.fill" }
        if isSpeaking { return "waveform" }
        return "mic"
    }

    private var titleText: String {
        if isProcessing { return "Processing turn" }
        if isActive { return "Release to send" }
        if isSpeaking { return "Assistant speaking" }
        return "Hold to talk"
    }

    private var subtitleText: String {
        if isProcessing { return "Translating and preparing speech" }
        if isActive { return "You're live" }
        if isSpeaking { return "Press to interrupt and speak again" }
        return "Press, hold, then release to translate"
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
            .animation(SaphanMotion.quickSpring, value: isPressed)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let center = CGPoint(x: 85, y: 85)
                        let distance = hypot(value.location.x - center.x, value.location.y - center.y)
                        let isInside = distance <= 98

                        if !isPressed {
                            isPressed = true
                            isInsideTouchRegion = true
                            hasTriggeredHold = false
                            onPressDown()
                            startHoldConfirmationTimer()
                        }

                        if isInside != isInsideTouchRegion {
                            isInsideTouchRegion = isInside

                            if !isInside {
                                if hasTriggeredHold {
                                    onCancel()
                                }
                                resetGestureState()
                            }
                        }
                    }
                    .onEnded { _ in
                        defer { resetGestureState() }
                        guard isInsideTouchRegion else { return }

                        if hasTriggeredHold {
                            onRelease()
                        } else {
                            onCancel()
                        }
                    }
            )
            .onAppear {
                pulse = true
            }
            .onDisappear {
                if isPressed {
                    onCancel()
                }
                resetGestureState()
            }

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

private extension PTTButtonView {
    func startHoldConfirmationTimer() {
        holdTask?.cancel()
        holdTask = Task {
            try? await Task.sleep(nanoseconds: holdConfirmationThreshold)
            guard !Task.isCancelled else { return }
            guard isPressed, isInsideTouchRegion, !hasTriggeredHold else { return }
            hasTriggeredHold = true
            onHoldConfirmed()
        }
    }

    func resetGestureState() {
        holdTask?.cancel()
        holdTask = nil
        isPressed = false
        isInsideTouchRegion = true
        hasTriggeredHold = false
    }
}

#Preview {
    VStack(spacing: 24) {
        PTTButtonView(
            isActive: false,
            isProcessing: false,
            isSpeaking: false,
            onPressDown: { },
            onHoldConfirmed: { },
            onRelease: { },
            onCancel: { }
        )
        PTTButtonView(
            isActive: true,
            isProcessing: false,
            isSpeaking: false,
            onPressDown: { },
            onHoldConfirmed: { },
            onRelease: { },
            onCancel: { }
        )
    }
    .padding()
}
