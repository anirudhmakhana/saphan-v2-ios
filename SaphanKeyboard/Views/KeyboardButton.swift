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
                .background(isPressed ? style.backgroundColor.opacity(0.7) : style.backgroundColor)
                .foregroundStyle(style.foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: .black.opacity(0.25), radius: 0.5, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .frame(height: height)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
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
