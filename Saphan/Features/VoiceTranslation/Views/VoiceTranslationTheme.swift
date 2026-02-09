import SwiftUI
import SaphanCore

enum SaphanTheme {
    struct Palette {
        let backgroundTop: Color
        let backgroundBottom: Color
        let surface: Color
        let elevatedSurface: Color
        let stroke: Color
        let primaryText: Color
        let secondaryText: Color
        let accent: Color
        let secondaryAccent: Color
        let accentSoft: Color
        let success: Color
        let warning: Color
        let danger: Color
    }

    /// Sunset Coral — the brand's primary accent
    static let brandCoral = Color.rgb(224, 120, 86)

    static func palette(for scheme: ColorScheme) -> Palette {
        if scheme == .dark {
            return Palette(
                backgroundTop: .rgb(21, 23, 24),
                backgroundBottom: .rgb(26, 26, 28),
                surface: .rgb(30, 30, 30),
                elevatedSurface: .rgb(44, 44, 46),
                stroke: .rgb(58, 58, 60),
                primaryText: .rgb(236, 237, 238),
                secondaryText: .rgb(155, 161, 166),
                accent: .rgb(224, 120, 86),
                secondaryAccent: .rgb(193, 162, 139),
                accentSoft: .rgb(60, 42, 36),
                success: .rgb(52, 199, 89),
                warning: .rgb(221, 164, 71),
                danger: .rgb(255, 114, 114)
            )
        }

        return Palette(
            backgroundTop: .white,
            backgroundBottom: .rgb(249, 247, 244),
            surface: .rgb(249, 247, 244),
            elevatedSurface: .white,
            stroke: .rgb(219, 216, 210),
            primaryText: .rgb(44, 44, 46),
            secondaryText: .rgb(104, 112, 118),
            accent: .rgb(224, 120, 86),
            secondaryAccent: .rgb(193, 162, 139),
            accentSoft: .rgb(252, 237, 230),
            success: .rgb(52, 199, 89),
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

    /// Full-screen dark gradient for auth / splash screens
    static func authBackgroundGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                .rgb(44, 44, 46),
                .rgb(26, 26, 26),
                .rgb(15, 15, 15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func primaryCTA(for scheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [.rgb(224, 120, 86), .rgb(208, 106, 74)],
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
            return dark ? .rgb(170, 170, 178) : .rgb(100, 100, 110)
        case "dating":
            return dark ? .rgb(240, 140, 150) : .rgb(200, 80, 100)
        case "business":
            return dark ? .rgb(130, 160, 200) : .rgb(60, 100, 160)
        case "travel":
            return dark ? .rgb(120, 200, 180) : .rgb(40, 140, 110)
        case "emergency":
            return dark ? .rgb(240, 120, 120) : .rgb(200, 70, 70)
        default:
            return palette(for: scheme).accent
        }
    }
}

/// Keep the old name as a typealias so any straggling references still compile
typealias VoiceTranslationTheme = SaphanTheme

struct SaphanPressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var pressedOpacity: Double = 0.9

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.76), value: configuration.isPressed)
    }
}

enum SaphanMotion {
    static let quickSpring = Animation.spring(response: 0.28, dampingFraction: 0.82)
    static let smoothSpring = Animation.spring(response: 0.36, dampingFraction: 0.84)
    static let quickEase = Animation.easeInOut(duration: 0.2)
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
