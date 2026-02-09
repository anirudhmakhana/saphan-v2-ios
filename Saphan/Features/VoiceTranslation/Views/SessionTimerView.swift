import SwiftUI
import SaphanCore

/// Displays session duration and connection status
struct SessionTimerView: View {
    let duration: String
    let connectionState: ConnectionState

    @Environment(\.colorScheme) private var colorScheme
    @State private var pulse = false

    private var palette: SaphanTheme.Palette {
        SaphanTheme.palette(for: colorScheme)
    }

    private var statusColor: Color {
        SaphanTheme.connectionTint(for: connectionState, in: colorScheme)
    }

    private var statusText: String {
        switch connectionState {
        case .connected: return "Live"
        case .connecting: return "Connecting"
        case .disconnected: return "Offline"
        case .error: return "Connection Issue"
        }
    }

    private var detailText: String {
        switch connectionState {
        case .connected:
            return "Translation is active"
        case .connecting:
            return "Setting up audio and network"
        case .disconnected:
            return "Ready when you are"
        case .error(let message):
            return message
        }
    }

    private var shouldShowDuration: Bool {
        connectionState == .connected
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 9, height: 9)
                    .shadow(color: statusColor.opacity(0.6), radius: 6)
                    .scaleEffect(pulse && (connectionState == .connected || connectionState == .connecting) ? 1.18 : 1.0)
                    .opacity(pulse && connectionState == .connected ? 0.75 : 1.0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

                Text(statusText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(statusColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(statusColor.opacity(colorScheme == .dark ? 0.18 : 0.12))
            )

            Text(detailText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(palette.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 6)

            if shouldShowDuration {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                        .font(.system(size: 11, weight: .semibold))
                    Text(duration)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(palette.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(palette.elevatedSurface)
                )
                .overlay(
                    Capsule()
                        .stroke(palette.stroke.opacity(0.85), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(palette.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.stroke.opacity(0.8), lineWidth: 1)
        )
        .onAppear {
            pulse = true
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SessionTimerView(duration: "00:00", connectionState: .disconnected)
        SessionTimerView(duration: "00:00", connectionState: .connecting)
        SessionTimerView(duration: "04:38", connectionState: .connected)
    }
    .padding()
}
