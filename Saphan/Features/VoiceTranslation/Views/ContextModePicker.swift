import SwiftUI
import SaphanCore

/// Horizontal scrolling picker for context modes
struct ContextModePicker: View {
    @Binding var selectedMode: ContextMode
    var isEnabled: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    private var palette: SaphanTheme.Palette {
        SaphanTheme.palette(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Context")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.secondaryText)

                Spacer()

                Text(selectedMode.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SaphanTheme.contextTint(for: selectedMode, in: colorScheme))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(palette.elevatedSurface)
                    )
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ContextMode.allModes) { mode in
                            ContextModeChip(
                                mode: mode,
                                isSelected: selectedMode.id == mode.id,
                                isEnabled: isEnabled,
                                colorScheme: colorScheme
                            ) {
                                guard isEnabled else { return }
                                withAnimation(SaphanMotion.quickSpring) {
                                    selectedMode = mode
                                    proxy.scrollTo(mode.id, anchor: .center)
                                }
                                HapticManager.shared.selection()
                            }
                            .id(mode.id)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

private struct ContextModeChip: View {
    let mode: ContextMode
    let isSelected: Bool
    let isEnabled: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    private var palette: SaphanTheme.Palette {
        SaphanTheme.palette(for: colorScheme)
    }

    private var tint: Color {
        SaphanTheme.contextTint(for: mode, in: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : tint)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? tint.opacity(0.16) : tint.opacity(0.12))
                    )

                Text(mode.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : palette.primaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? tint : palette.elevatedSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.25) : palette.stroke.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: isSelected ? tint.opacity(0.25) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(SaphanPressableStyle(scale: 0.97, pressedOpacity: 0.95))
        .disabled(!isEnabled)
    }
}

#Preview {
    ContextModePicker(selectedMode: .constant(.social))
        .padding()
}
