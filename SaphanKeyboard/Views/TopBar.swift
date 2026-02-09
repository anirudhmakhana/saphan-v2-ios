import SwiftUI
import SaphanCore

struct TopBar: View {
    @ObservedObject var viewModel: KeyboardViewModel
    @State private var showLanguagePicker = false
    @State private var showTonePicker = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            modeToggle
                .frame(width: 84, alignment: .leading)

            Spacer(minLength: 8)

            languagePairButton

            Spacer(minLength: 8)

            toneSlot
                .frame(width: 86, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(height: Constants.UI.topBarHeight)
        .background(Color(.secondarySystemBackground).opacity(colorScheme == .dark ? 0.92 : 0.96))
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerSheet(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTonePicker) {
            TonePickerSheet(viewModel: viewModel)
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: viewModel.mode)
    }

    private var modeToggle: some View {
        HStack(spacing: 2) {
            modeButton(mode: .understand, icon: "ear")
            modeButton(mode: .reply, icon: "bubble.right")
        }
        .padding(3)
        .background(Color(.tertiarySystemBackground))
        .overlay(
            Capsule()
                .stroke(Color.black.opacity(colorScheme == .dark ? 0.18 : 0.1), lineWidth: 0.8)
        )
        .clipShape(Capsule())
    }

    private func modeButton(mode: KeyboardTranslationMode, icon: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.mode = mode
            }
            HapticManager.impact(.light)
        } label: {
            Image(systemName: icon)
                .font(.subheadline)
                .frame(width: 32, height: 28)
                .background(viewModel.mode == mode ? Color.accentColor : Color.clear)
                .foregroundStyle(viewModel.mode == mode ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(KeyboardPressableStyle(scale: 0.94))
        .accessibilityLabel(mode == .understand ? "Understand mode" : "Reply mode")
    }

    private var languagePairButton: some View {
        Button {
            showLanguagePicker = true
            HapticManager.impact(.light)
        } label: {
            HStack(spacing: 6) {
                Text(viewModel.languagePair.source.code.uppercased())
                    .font(.caption.bold())

                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(viewModel.languagePair.target.code.uppercased())
                    .font(.caption.bold())

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemBackground))
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(colorScheme == .dark ? 0.18 : 0.08), lineWidth: 0.7)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(KeyboardPressableStyle(scale: 0.96))
    }

    @ViewBuilder
    private var toneSlot: some View {
        if viewModel.mode == .reply {
            toneButton
                .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            Color.clear
        }
    }

    private var toneButton: some View {
        Button {
            showTonePicker = true
            HapticManager.impact(.light)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.tone.icon)
                    .font(.caption2)
                Text(viewModel.tone.displayName)
                    .font(.caption2.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemBackground))
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(colorScheme == .dark ? 0.18 : 0.08), lineWidth: 0.7)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(KeyboardPressableStyle(scale: 0.96))
    }
}

struct LanguagePickerSheet: View {
    @ObservedObject var viewModel: KeyboardViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSource: Language
    @State private var selectedTarget: Language

    init(viewModel: KeyboardViewModel) {
        self.viewModel = viewModel
        _selectedSource = State(initialValue: viewModel.languagePair.source)
        _selectedTarget = State(initialValue: viewModel.languagePair.target)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Wheel pickers side by side
                HStack(spacing: 0) {
                    // Source language picker
                    VStack(spacing: 4) {
                        Text("From")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Source", selection: $selectedSource) {
                            ForEach(Language.allLanguages) { language in
                                Text("\(language.flag) \(language.name)")
                                    .tag(language)
                            }
                        }
                        .pickerStyle(.wheel)
                    }

                    // Swap button in the middle
                    Button {
                        let temp = selectedSource
                        selectedSource = selectedTarget
                        selectedTarget = temp
                        HapticManager.impact(.light)
                    } label: {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.top, 20)

                    // Target language picker
                    VStack(spacing: 4) {
                        Text("To")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Target", selection: $selectedTarget) {
                            ForEach(Language.allLanguages) { language in
                                Text("\(language.flag) \(language.name)")
                                    .tag(language)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.languagePair = LanguagePair(
                            source: selectedSource,
                            target: selectedTarget
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct TonePickerSheet: View {
    @ObservedObject var viewModel: KeyboardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Tone.allCases) { tone in
                    Button {
                        viewModel.tone = tone
                        dismiss()
                    } label: {
                        ToneRow(
                            tone: tone,
                            isSelected: tone == viewModel.tone
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Tone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct LanguagePairRow: View {
    let pair: LanguagePair
    let isSelected: Bool

    var body: some View {
        HStack {
            Text("\(pair.source.flag) \(pair.source.name)")
            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)
            Text("\(pair.target.flag) \(pair.target.name)")

            if isSelected {
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
    }
}

private struct LanguageRow: View {
    let language: Language
    let isSelected: Bool

    var body: some View {
        HStack {
            Text("\(language.flag) \(language.name)")
                .foregroundStyle(.primary)
            Text(language.nativeName)
                .foregroundStyle(.secondary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
    }
}

private struct ToneRow: View {
    let tone: Tone
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: tone.icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            VStack(alignment: .leading) {
                Text(tone.displayName)
                    .foregroundStyle(.primary)
                Text(tone.promptDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
    }
}

#Preview {
    TopBar(viewModel: KeyboardViewModel())
}
