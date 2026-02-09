import SwiftUI
import SaphanCore

struct ActionBar: View {
    @ObservedObject var viewModel: KeyboardViewModel
    @State private var showCopiedToast = false
    @State private var copiedToastWorkItem: DispatchWorkItem?

    var body: some View {
        HStack(spacing: 8) {
            pasteButton
            copyButton
            clearButton
            translateButton

            Spacer()

            insertButton
        }
        .padding(.horizontal, 12)
        .frame(height: Constants.UI.actionBarHeight)
        .background(Color(.secondarySystemBackground))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5)
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                copiedToast
            }
        }
    }

    private var copyButton: some View {
        Button {
            viewModel.copyTranslation()
            showCopiedToastWithAutoDismiss()
            HapticManager.notification(.success)
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.subheadline)
                .foregroundStyle(viewModel.canCopy ? .primary : .secondary)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(!viewModel.canCopy)
        .accessibilityLabel("Copy")
    }

    private var clearButton: some View {
        Button {
            viewModel.clear()
            HapticManager.impact(.light)
        } label: {
            Image(systemName: "xmark.circle")
                .font(.subheadline)
                .foregroundStyle(viewModel.canClear ? .primary : .secondary)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(!viewModel.canClear)
        .accessibilityLabel("Clear")
    }

    private var insertButton: some View {
        Button {
            viewModel.insertTranslation()
            HapticManager.notification(.success)
        } label: {
            Label("Insert", systemImage: "arrow.turn.down.left")
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .disabled(!viewModel.canInsert)
        .accessibilityLabel("Insert")
    }

    private var translateButton: some View {
        Button {
            viewModel.requestTranslation()
            HapticManager.impact(.medium)
        } label: {
            Group {
                if viewModel.state == .loading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .disabled(!viewModel.canTranslate)
        .accessibilityLabel("Translate")
    }

    private var pasteButton: some View {
        Button {
            viewModel.paste()
            HapticManager.selection()
        } label: {
            Image(systemName: "doc.on.clipboard")
                .font(.subheadline)
                .foregroundStyle(viewModel.canPaste ? .primary : .secondary)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(!viewModel.canPaste)
        .accessibilityLabel("Paste")
    }

    private var copiedToast: some View {
        Text("Copied!")
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.75))
            .clipShape(Capsule())
            .offset(y: -8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.18), value: showCopiedToast)
    }

    private func showCopiedToastWithAutoDismiss() {
        copiedToastWorkItem?.cancel()
        withAnimation(.easeInOut(duration: 0.18)) {
            showCopiedToast = true
        }

        let workItem = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.18)) {
                showCopiedToast = false
            }
        }
        copiedToastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
    }
}

#Preview {
    VStack {
        ActionBar(viewModel: KeyboardViewModel())

        ActionBar(viewModel: {
            let vm = KeyboardViewModel()
            vm.inputText = "Hello"
            vm.translationPreview = "สวัสดี"
            vm.state = .ready
            return vm
        }())
    }
}
