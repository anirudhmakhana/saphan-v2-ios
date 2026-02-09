import SwiftUI
import SaphanCore

struct ConversationHistorySheet: View {
    let history: [ConversationItem]
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var palette: SaphanTheme.Palette {
        SaphanTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    if history.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 36))
                                .foregroundStyle(palette.secondaryText.opacity(0.5))
                            Text("No conversation yet")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(palette.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(history) { item in
                                ConversationBubbleView(item: item)
                                    .id(item.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .onAppear {
                    if let last = history.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .navigationTitle("Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !history.isEmpty {
                        Button("Clear", role: .destructive) {
                            onClear()
                        }
                        .foregroundStyle(palette.danger)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ConversationHistorySheet(
        history: [
            ConversationItem(role: .user, text: "Where is the nearest train station?"),
            ConversationItem(role: .assistant, text: "สถานีรถไฟที่ใกล้ที่สุดอยู่ที่ไหน?"),
            ConversationItem(role: .user, text: "How much does a ticket cost?"),
            ConversationItem(role: .assistant, text: "ตั๋วราคาเท่าไหร่?"),
        ],
        onClear: {}
    )
}
