import SwiftUI
import SaphanCore

/// Chat bubble for displaying conversation items
struct ConversationBubbleView: View {
    let item: ConversationItem
    @Environment(\.colorScheme) private var colorScheme
    private static let bubbleTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private var palette: SaphanTheme.Palette {
        SaphanTheme.palette(for: colorScheme)
    }

    private var isUser: Bool {
        item.role == .user
    }

    private var alignment: HorizontalAlignment {
        isUser ? .trailing : .leading
    }

    private var labelText: String {
        isUser ? "You" : "Translation"
    }

    private var timeFormatted: String {
        Self.bubbleTimeFormatter.string(from: item.timestamp)
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 56) }

            VStack(alignment: alignment, spacing: 5) {
                Text(labelText)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.secondaryText)

                Text(item.text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(isUser ? Color.white : palette.primaryText)
                    .multilineTextAlignment(isUser ? .trailing : .leading)
                    .frame(maxWidth: 320, alignment: isUser ? .trailing : .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if isUser {
                                LinearGradient(
                                    colors: [palette.accent.opacity(0.98), palette.accent.opacity(0.82)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                palette.elevatedSurface
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isUser ? palette.accent.opacity(0.25) : palette.stroke.opacity(0.85), lineWidth: 1)
                    )
                    .textSelection(.enabled)

                Text(timeFormatted)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
            }

            if !isUser { Spacer(minLength: 56) }
        }
    }
}

#Preview {
    VStack(spacing: 14) {
        ConversationBubbleView(
            item: ConversationItem(
                id: "1",
                role: .user,
                text: "Can you tell me where the nearest train station is?",
                timestamp: Date()
            )
        )
        ConversationBubbleView(
            item: ConversationItem(
                id: "2",
                role: .assistant,
                text: "สถานีรถไฟที่ใกล้ที่สุดอยู่ห่างจากที่นี่ประมาณ 5 นาที",
                timestamp: Date()
            )
        )
    }
    .padding()
}
