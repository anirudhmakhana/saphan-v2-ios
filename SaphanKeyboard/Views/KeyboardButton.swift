import SwiftUI

enum KeyboardButtonStyle {
    case character
    case special
    case highlighted
    case space

    var backgroundColor: Color {
        switch self {
        case .character:
            return Color(.systemBackground)
        case .special:
            return Color(.systemGray3)
        case .highlighted:
            return Color.accentColor
        case .space:
            return Color(.systemBackground)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .character, .special, .space:
            return .primary
        case .highlighted:
            return .white
        }
    }
}

struct KeyboardPressableStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    var pressedOpacity: Double = 0.9

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct KeyboardButton: View {
    let title: String?
    let icon: String?
    let style: KeyboardButtonStyle
    let height: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    init(
        title: String? = nil,
        icon: String? = nil,
        style: KeyboardButtonStyle,
        height: CGFloat = 42,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.height = height
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isPressed ? style.backgroundColor.opacity(0.76) : style.backgroundColor)
                .foregroundStyle(style.foregroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.black.opacity(isPressed ? 0.06 : 0.12), lineWidth: 0.6)
                )
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .shadow(color: .black.opacity(isPressed ? 0.12 : 0.2), radius: isPressed ? 0.2 : 0.7, x: 0, y: 1)
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.18, dampingFraction: 0.72), value: isPressed)
        }
        .buttonStyle(.plain)
        .frame(height: height)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }

    @ViewBuilder
    private var content: some View {
        if let icon = icon {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
        } else if let title = title {
            if title == "space" {
                Text("")
            } else if title == "return" {
                Image(systemName: "return")
                    .font(.system(size: 16, weight: .regular))
            } else if title.count == 1 {
                Text(title)
                    .font(.system(size: 22, weight: .regular))
            } else {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
            }
        }
    }
}

#Preview {
    HStack {
        KeyboardButton(title: "A", style: .character) {}
        KeyboardButton(icon: "shift", style: .special) {}
        KeyboardButton(icon: "shift.fill", style: .highlighted) {}
        KeyboardButton(title: "space", style: .space) {}
    }
    .padding()
    .background(Color(.systemGray5))
}
