import SwiftUI
import SaphanCore

enum VoiceTranslationTheme {
    struct Palette {
        let backgroundTop: Color
        let backgroundBottom: Color
        let surface: Color
        let elevatedSurface: Color
        let stroke: Color
        let primaryText: Color
        let secondaryText: Color
        let accent: Color
        let accentSoft: Color
        let success: Color
        let warning: Color
        let danger: Color
    }

    static func palette(for scheme: ColorScheme) -> Palette {
        if scheme == .dark {
            return Palette(
                backgroundTop: .rgb(11, 16, 24),
                backgroundBottom: .rgb(18, 27, 40),
                surface: .rgb(23, 33, 47),
                elevatedSurface: .rgb(30, 42, 60),
                stroke: .rgb(47, 62, 84),
                primaryText: .rgb(244, 248, 255),
                secondaryText: .rgb(169, 182, 203),
                accent: .rgb(94, 165, 255),
                accentSoft: .rgb(37, 56, 83),
                success: .rgb(62, 201, 136),
                warning: .rgb(221, 164, 71),
                danger: .rgb(255, 114, 114)
            )
        }

        return Palette(
            backgroundTop: .rgb(246, 248, 252),
            backgroundBottom: .rgb(234, 239, 247),
            surface: .white.opacity(0.92),
            elevatedSurface: .rgb(244, 247, 252),
            stroke: .rgb(219, 227, 239),
            primaryText: .rgb(20, 28, 40),
            secondaryText: .rgb(98, 111, 130),
            accent: .rgb(21, 126, 239),
            accentSoft: .rgb(219, 236, 255),
            success: .rgb(46, 165, 107),
            warning: .rgb(208, 139, 49),
            danger: .rgb(215, 78, 78)
        )
    }

    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        let palette = palette(for: scheme)
        return LinearGradient(
            colors: [palette.backgroundTop, palette.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func primaryCTA(for scheme: ColorScheme) -> LinearGradient {
        let palette = palette(for: scheme)
        let accent = palette.accent
        return LinearGradient(
            colors: [accent.opacity(0.95), accent.opacity(0.78)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func destructiveCTA(for scheme: ColorScheme) -> LinearGradient {
        let palette = palette(for: scheme)
        return LinearGradient(
            colors: [palette.danger.opacity(0.96), palette.danger.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func connectionTint(for state: ConnectionState, in scheme: ColorScheme) -> Color {
        let palette = palette(for: scheme)
        switch state {
        case .connected:
            return palette.success
        case .connecting:
            return palette.warning
        case .disconnected:
            return palette.secondaryText.opacity(0.7)
        case .error:
            return palette.danger
        }
    }

    static func contextTint(for mode: ContextMode, in scheme: ColorScheme) -> Color {
        let dark = scheme == .dark
        switch mode.id {
        case "social":
            return dark ? .rgb(111, 183, 255) : .rgb(24, 124, 228)
        case "dating":
            return dark ? .rgb(255, 143, 167) : .rgb(211, 78, 108)
        case "business":
            return dark ? .rgb(145, 202, 255) : .rgb(40, 108, 190)
        case "travel":
            return dark ? .rgb(128, 232, 196) : .rgb(26, 148, 102)
        case "emergency":
            return dark ? .rgb(255, 139, 139) : .rgb(205, 77, 77)
        default:
            return palette(for: scheme).accent
        }
    }
}

private extension Color {
    static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(
            red: red / 255.0,
            green: green / 255.0,
            blue: blue / 255.0
        )
    }
}
