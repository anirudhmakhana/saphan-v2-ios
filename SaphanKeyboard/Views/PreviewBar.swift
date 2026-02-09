import SwiftUI
import SaphanCore

struct PreviewBar: View {
    @ObservedObject var viewModel: KeyboardViewModel
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(height: isExpanded ? Constants.UI.previewBarExpandedHeight : Constants.UI.previewBarCollapsedHeight)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
        .background(Color(.systemBackground))
        .onTapGesture {
            if viewModel.state != .idle {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
        .onChange(of: viewModel.state) { newState in
            if newState == .error || newState == .ready {
                withAnimation {
                    isExpanded = true
                }
            } else if newState == .idle {
                withAnimation {
                    isExpanded = false
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            idleView
        case .typing:
            typingView
        case .loading:
            loadingView
        case .ready:
            readyView
        case .error:
            errorView
        case .fullAccessRequired:
            fullAccessRequiredView
        }
    }

    private var idleView: some View {
        HStack {
            Image(systemName: viewModel.mode == .understand ? "doc.on.clipboard" : "keyboard")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.mode == .understand ? "Tap Paste to translate clipboard" : "Type, then tap Translate")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if viewModel.mode == .understand {
                    Text("Requires Full Access")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var typingView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !viewModel.inputText.isEmpty {
                Text(viewModel.inputText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(isExpanded ? 2 : 1)
            }

            if let preview = viewModel.translationPreview {
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(isExpanded ? 3 : 1)
            } else {
                Text("Tap Translate")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)

            VStack(alignment: .leading, spacing: 2) {
                Text("Translating...")
                    .font(.subheadline)

                if !viewModel.inputText.isEmpty {
                    Text(viewModel.inputText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var readyView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isExpanded {
                HStack {
                    Text("Original")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Text(viewModel.inputText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(viewModel.translationPreview ?? "")
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(isExpanded ? 3 : 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var errorView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.errorMessage ?? "Translation failed")
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Button {
                    viewModel.retry()
                } label: {
                    Text("Tap to retry")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var fullAccessRequiredView: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Enable Full Access")
                    .font(.subheadline.weight(.medium))

                Text("Required for translation. Go to Settings > Keyboards > Saphan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack {
        PreviewBar(viewModel: {
            let vm = KeyboardViewModel()
            return vm
        }())

        PreviewBar(viewModel: {
            let vm = KeyboardViewModel()
            vm.inputText = "Hello, how are you?"
            vm.translationPreview = "สวัสดี สบายดีไหม?"
            vm.state = .ready
            return vm
        }())

        PreviewBar(viewModel: {
            let vm = KeyboardViewModel()
            vm.state = .loading
            return vm
        }())

        PreviewBar(viewModel: {
            let vm = KeyboardViewModel()
            vm.state = .error
            vm.errorMessage = "No internet connection"
            return vm
        }())
    }
    .padding()
}
