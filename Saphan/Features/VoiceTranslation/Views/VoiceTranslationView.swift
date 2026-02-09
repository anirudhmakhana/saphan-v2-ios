import SwiftUI
import SaphanCore

/// Mic-first translation screen with 3-zone split layout:
/// top bar (fixed), transcript (scrollable), mic zone (fixed at bottom).
struct VoiceTranslationView: View {
    @StateObject private var viewModel = VoiceTranslationViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @State private var isMicHeld = false
    @State private var isPremium = false
    @State private var showPaywall = false
    @State private var showAdvancedControls = false
    @State private var showConversationHistory = false

    private var palette: SaphanTheme.Palette {
        SaphanTheme.palette(for: colorScheme)
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.error = nil
                }
            }
        )
    }

    private var latestSourceTranscript: String? {
        viewModel.history.last(where: { $0.role == .user })?.text
    }

    private var latestTranslation: String? {
        viewModel.history.last(where: { $0.role == .assistant })?.text
    }

    private var exchangeCount: Int {
        viewModel.history.filter { $0.role == .user }.count
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            SaphanTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                transcriptZone

                micZone
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .animation(SaphanMotion.smoothSpring, value: viewModel.connectionState)
        .animation(SaphanMotion.smoothSpring, value: viewModel.history.count)
        .sheet(isPresented: $viewModel.showLanguage2Picker) {
            LanguagePickerSheet(
                selectedLanguage: $viewModel.language2,
                title: "Choose target language",
                excludedLanguageCode: viewModel.language1.code
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showVoicePicker) {
            VoicePickerSheet(selectedVoice: $viewModel.selectedVoice)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAdvancedControls) {
            AdvancedTranslationControlsSheet(
                isPremium: isPremium,
                interactionMode: $viewModel.interactionMode,
                contextMode: $viewModel.contextMode,
                selectedVoice: $viewModel.selectedVoice,
                onUpgradeTap: { showPaywall = true },
                onModeChanged: { newMode in
                    selectInteractionMode(newMode)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showConversationHistory) {
            ConversationHistorySheet(
                history: viewModel.history,
                onClear: {
                    viewModel.clearHistory()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .onDisappear {
                    refreshPremiumState()
                }
        }
        .alert("Translation Error", isPresented: errorAlertBinding) {
            Button("Dismiss", role: .cancel) {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error ?? "Unknown error")
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background && viewModel.isConnected {
                Task {
                    await viewModel.disconnect()
                }
            } else if newPhase == .active {
                refreshPremiumState()
            }
        }
        .onChange(of: viewModel.connectionState) { newState in
            if newState == .connected &&
                isMicHeld &&
                viewModel.interactionMode == .ptt &&
                !viewModel.isPTTActive {
                viewModel.pttPressed()
            }

            if newState != .connected {
                isMicHeld = false
            }
        }
        .onAppear {
            refreshPremiumState()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 10) {
            statusChip

            Spacer(minLength: 8)

            Button {
                viewModel.showLanguage2Picker = true
                HapticManager.selection()
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.language2.flag)
                        .font(.system(size: 18))
                    Text(viewModel.language2.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.accent)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(palette.secondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(palette.elevatedSurface)
                )
                .overlay(
                    Capsule()
                        .stroke(palette.stroke.opacity(0.85), lineWidth: 1)
                )
            }
            .buttonStyle(SaphanPressableStyle(scale: 0.97))
        }
    }

    private var statusChip: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(SaphanTheme.connectionTint(for: viewModel.connectionState, in: colorScheme))
                .frame(width: 8, height: 8)
            Text(connectionStatusText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SaphanTheme.connectionTint(for: viewModel.connectionState, in: colorScheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(SaphanTheme.connectionTint(for: viewModel.connectionState, in: colorScheme).opacity(0.15))
        )
    }

    private var connectionStatusText: String {
        switch viewModel.connectionState {
        case .connected:
            return "Ready"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Idle"
        case .error:
            return "Issue"
        }
    }

    // MARK: - Transcript Zone

    private var transcriptZone: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 16)

                if latestSourceTranscript == nil && latestTranslation == nil {
                    contextualHint
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    latestTranscriptBlock
                        .padding(.top, 12)
                }

                if exchangeCount > 1 {
                    conversationHistoryLink
                        .padding(.top, 16)
                }

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 20)
        }
        .frame(maxHeight: .infinity)
    }

    private var contextualHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 34))
                .foregroundStyle(palette.accent.opacity(0.6))

            Text("Hold the mic and speak naturally.")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.primaryText)
                .multilineTextAlignment(.center)

            Text("Auto-detects \(viewModel.language1.name) and \(viewModel.language2.name)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private var latestTranscriptBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let source = latestSourceTranscript {
                VStack(alignment: .leading, spacing: 5) {
                    Text("YOU SAID")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                        .tracking(0.5)

                    Text(source)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                        .textSelection(.enabled)
                }
            }

            if let translation = latestTranslation {
                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.language2.name.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.accent)
                        .tracking(0.5)

                    Text(translation)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(palette.accent)
                        .textSelection(.enabled)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var conversationHistoryLink: some View {
        Button {
            showConversationHistory = true
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .semibold))
                Text("View conversation (\(exchangeCount) exchanges)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(palette.secondaryText)
        }
        .buttonStyle(SaphanPressableStyle(scale: 0.97))
    }

    // MARK: - Mic Zone

    private var micZone: some View {
        VStack(spacing: 8) {
            if viewModel.interactionMode == .vad && viewModel.isConnected {
                VADIndicatorView(isSpeaking: viewModel.isSpeaking)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            PTTButtonView(
                isActive: viewModel.isPTTActive,
                isSpeaking: viewModel.isSpeaking,
                onPressDown: handlePTTPressDown,
                onPressUp: handlePTTPressUp
            )

            secondaryControlsRow
        }
    }

    private var secondaryControlsRow: some View {
        HStack(spacing: 0) {
            Button {
                showAdvancedControls = true
                HapticManager.selection()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Advanced")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(palette.secondaryText)
            }
            .buttonStyle(SaphanPressableStyle(scale: 0.97))

            Spacer()

            if viewModel.isConnected {
                Text(viewModel.sessionDurationFormatted)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(palette.secondaryText)

                Spacer()

                Button {
                    Task {
                        await viewModel.disconnect()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("End")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(palette.danger)
                }
                .buttonStyle(SaphanPressableStyle(scale: 0.97))
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Actions

    private func refreshPremiumState() {
        if let expirationDate = PreferencesService.shared.subscriptionExpirationDate {
            isPremium = expirationDate > Date()
        } else {
            isPremium = false
        }

        if !isPremium && viewModel.interactionMode != .ptt {
            viewModel.interactionMode = .ptt
            if viewModel.isConnected {
                viewModel.toggleInteractionMode()
            }
        }
    }

    private func selectInteractionMode(_ mode: InteractionMode) {
        guard mode != .vad || isPremium else {
            showPaywall = true
            return
        }

        guard viewModel.interactionMode != mode else { return }
        viewModel.interactionMode = mode

        if viewModel.isConnected {
            viewModel.toggleInteractionMode()
        }

        HapticManager.selection()
    }

    private func handlePTTPressDown() {
        isMicHeld = true

        if viewModel.interactionMode != .ptt {
            selectInteractionMode(.ptt)
        }

        if viewModel.isConnected {
            viewModel.pttPressed()
            return
        }

        guard viewModel.connectionState != .connecting else { return }

        Task {
            await viewModel.connect()
            if isMicHeld && viewModel.interactionMode == .ptt {
                viewModel.pttPressed()
            } else if viewModel.isConnected && viewModel.interactionMode == .ptt {
                await viewModel.disconnect()
            }
        }
    }

    private func handlePTTPressUp() {
        isMicHeld = false
        viewModel.pttReleased()
    }
}

// MARK: - Feature Row (used in Advanced sheet)

private struct FeatureRow: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)

            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Language Picker Sheet
struct LanguagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLanguage: Language
    let title: String
    var excludedLanguageCode: String? = nil
    @State private var searchText = ""

    private var filteredLanguages: [Language] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let available = Language.allLanguages.filter { language in
            guard let excludedLanguageCode else { return true }
            return language.code != excludedLanguageCode
        }

        guard !query.isEmpty else { return available }
        return available.filter { language in
            language.name.localizedCaseInsensitiveContains(query) ||
            language.nativeName.localizedCaseInsensitiveContains(query) ||
            language.code.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredLanguages) { language in
                Button {
                    selectedLanguage = language
                    HapticManager.selection()
                    dismiss()
                } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(language.name)
                                .foregroundStyle(.primary)
                            Text("\(language.nativeName) \u{2022} \(language.code.uppercased())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if language.code == selectedLanguage.code {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(SaphanTheme.brandCoral)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search languages")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Advanced Controls Sheet
struct AdvancedTranslationControlsSheet: View {
    let isPremium: Bool
    @Binding var interactionMode: InteractionMode
    @Binding var contextMode: ContextMode
    @Binding var selectedVoice: VoiceOption
    let onUpgradeTap: () -> Void
    let onModeChanged: (InteractionMode) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var palette: SaphanTheme.Palette {
        SaphanTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interaction Mode")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.secondaryText)

                        Picker("Mode", selection: Binding(
                            get: { interactionMode },
                            set: { newMode in
                                onModeChanged(newMode)
                            }
                        )) {
                            Text("Push-to-Talk").tag(InteractionMode.ptt)
                            Text("Always-On").tag(InteractionMode.vad)
                        }
                        .pickerStyle(.segmented)
                        .disabled(!isPremium)

                        if !isPremium {
                            Text("Always-On requires Premium")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(palette.warning)
                        }
                    }
                    .padding(14)
                    .background(cardBackground)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voice")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.secondaryText)

                        Picker("Voice", selection: $selectedVoice) {
                            ForEach(VoiceOption.allCases) { voice in
                                Text(voice.rawValue.capitalized)
                                    .tag(voice)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(14)
                    .background(cardBackground)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Tone Context")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(palette.secondaryText)
                            Spacer()
                            if !isPremium {
                                Text("Premium")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(palette.warning)
                            }
                        }

                        ContextModePicker(selectedMode: $contextMode, isEnabled: isPremium)
                    }
                    .padding(14)
                    .background(cardBackground)

                    if !isPremium {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Premium unlocks")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(palette.secondaryText)

                            FeatureRow(icon: "lock.fill", text: "Always-on listening", tint: palette.warning)
                            FeatureRow(icon: "lock.fill", text: "Automatic speaker switching", tint: palette.warning)
                            FeatureRow(icon: "lock.fill", text: "Advanced tone by context/contact", tint: palette.warning)
                            FeatureRow(icon: "lock.fill", text: "Conversation memory", tint: palette.warning)
                            FeatureRow(icon: "lock.fill", text: "Vocabulary personalization", tint: palette.warning)
                            FeatureRow(icon: "lock.fill", text: "Transcript export", tint: palette.warning)
                            FeatureRow(icon: "lock.fill", text: "Offline language packs", tint: palette.warning)
                        }
                        .padding(14)
                        .background(cardBackground)

                        Button {
                            dismiss()
                            onUpgradeTap()
                        } label: {
                            Text("Unlock Always-On, Memory, Export, Offline Packs")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(SaphanTheme.primaryCTA(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(SaphanPressableStyle(scale: 0.98))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 18)
            }
            .navigationTitle("Advanced Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(palette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.stroke.opacity(0.85), lineWidth: 1)
            )
    }
}

// MARK: - Voice Picker Sheet
struct VoicePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedVoice: VoiceOption

    var body: some View {
        NavigationStack {
            List(VoiceOption.allCases) { voice in
                Button {
                    selectedVoice = voice
                    HapticManager.selection()
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(voice.rawValue.capitalized)
                                .foregroundStyle(.primary)
                                .font(.headline)

                            Text(voice.description)
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }

                        Spacer()

                        if voice == selectedVoice {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(SaphanTheme.brandCoral)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - VAD Indicator View
struct VADIndicatorView: View {
    let isSpeaking: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var palette: SaphanTheme.Palette {
        SaphanTheme.palette(for: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill((isSpeaking ? palette.warning : palette.accent).opacity(0.16))
                    .frame(width: 56, height: 56)

                Image(systemName: isSpeaking ? "waveform.circle.fill" : "waveform")
                    .font(.system(size: 25))
                    .foregroundStyle(isSpeaking ? palette.warning : palette.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isSpeaking ? "Listening now" : "Waiting for speech")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                Text("Hands-free mode is active.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke.opacity(0.8), lineWidth: 1)
        )
    }
}

#Preview {
    VoiceTranslationView()
}
