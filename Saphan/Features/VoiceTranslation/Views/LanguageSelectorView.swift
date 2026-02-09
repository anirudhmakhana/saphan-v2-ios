import SwiftUI
import SaphanCore

/// Language selector with swap functionality
struct LanguageSelectorView: View {
    let language1: Language
    let language2: Language
    let onLanguage1Tap: () -> Void
    let onLanguage2Tap: () -> Void
    let onSwapTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var swapRotation: Double = 0

    private var palette: SaphanTheme.Palette {
        SaphanTheme.palette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            LanguageCard(
                roleTitle: "From",
                language: language1,
                palette: palette,
                action: onLanguage1Tap
            )

            Button {
                withAnimation(SaphanMotion.quickSpring) {
                    swapRotation += 180
                }
                onSwapTap()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.accent)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(palette.accentSoft)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(palette.stroke.opacity(0.9), lineWidth: 1)
                    )
                    .rotationEffect(.degrees(swapRotation))
            }
            .buttonStyle(SaphanPressableStyle(scale: 0.92))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            LanguageCard(
                roleTitle: "To",
                language: language2,
                palette: palette,
                action: onLanguage2Tap
            )
        }
    }
}

private struct LanguageCard: View {
    let roleTitle: String
    let language: Language
    let palette: SaphanTheme.Palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(roleTitle)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
                    .textCase(.uppercase)

                HStack(spacing: 10) {
                    Text(language.flag)
                        .font(.system(size: 26))
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(palette.elevatedSurface)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(language.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(language.nativeName)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(palette.secondaryText.opacity(0.85))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 92)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(palette.elevatedSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.stroke.opacity(0.85), lineWidth: 1)
            )
        }
        .buttonStyle(SaphanPressableStyle(scale: 0.975))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview("English to Thai") {
    LanguageSelectorView(
        language1: .english,
        language2: .thai,
        onLanguage1Tap: { },
        onLanguage2Tap: { },
        onSwapTap: { }
    )
    .padding()
}
