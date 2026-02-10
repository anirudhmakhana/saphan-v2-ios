import SwiftUI
import SaphanCore

/// Mic-first translation screen with fixed top and bottom zones.
struct VoiceTranslationView: View {
    @StateObject private var viewModel = VoiceTranslationViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
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

    var body: some View {
        ZStack {
            SaphanTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                transcriptZone

                micZone
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .animation(SaphanMotion.smoothSpring, value: viewModel.connectionState)
        .animation(SaphanMotion.smoothSpring, value: viewModel.micTurnState)
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
        .sheet(isPresented: $showAdvancedControls) {
            AdvancedTranslationControlsSheet(
                isPremium: isPremium,
                preferredLanguage: Binding(
                    get: { viewModel.language1 },
                    set: { viewModel.updateLanguage1($0) }
                ),
                targetLanguageCode: viewModel.language2.code,
                audioOutputPreference: Binding(
                    get: { viewModel.audioOutputPreference },
                    set: { viewModel.setAudioOutputPreference($0) }
                ),
                currentOutputDeviceName: viewModel.currentOutputDeviceName,
                contextMode: $viewModel.contextMode,
                selectedVoice: $viewModel.selectedVoice,
                onUpgradeTap: { showPaywall = true }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showConversationHistory) {
            ConversationHistorySheet(
                history: viewModel.history,
                onClear: { viewModel.clearHistory() }
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
                viewModel.warmupRealtimeIfNeeded()
            }
        }
        .onAppear {
            refreshPremiumState()
            viewModel.warmupRealtimeIfNeeded()
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
                    Text("Target:")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.secondaryText)

                    Text(viewModel.language2.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
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
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(connectionStatusText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
    }

    private var connectionStatusText: String {
        switch viewModel.connectionState {
        case .connected:
            if viewModel.isOutputSpeaking {
                return "Speaking output"
            }
            if viewModel.isTranslating {
                return "Translating"
            }
            return "Listening"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return viewModel.isWarmupInProgress ? "Warming up" : "Idle"
        case .error:
            return "Issue"
        }
    }

    private var statusColor: Color {
        if viewModel.connectionState == .connected {
            if viewModel.isOutputSpeaking {
                return palette.accent
            }
            if viewModel.isTranslating {
                return palette.warning
            }
            return palette.accent
        }

        if viewModel.connectionState == .disconnected && viewModel.isWarmupInProgress {
            return palette.warning
        }

        return SaphanTheme.connectionTint(for: viewModel.connectionState, in: colorScheme)
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
            Image(systemName: contextualHintIcon)
                .font(.system(size: 34))
                .foregroundStyle(palette.accent.opacity(0.6))

            Text(contextualHintTitle)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.primaryText)
                .multilineTextAlignment(.center)

            Text(contextualHintSubtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private var contextualHintIcon: String {
        if viewModel.connectionState == .connected {
            if viewModel.isOutputSpeaking {
                return "speaker.wave.2.fill"
            }
            if viewModel.isTranslating {
                return "hourglass.circle.fill"
            }
            if viewModel.isSpeaking {
                return "waveform.circle.fill"
            }
            return "waveform.badge.mic"
        }
        return "mic.badge.plus"
    }

    private var contextualHintTitle: String {
        if viewModel.connectionState == .connected {
            if viewModel.isOutputSpeaking {
                return "Speaking translated output"
            }
            if viewModel.isTranslating {
                return "Translating now"
            }
            if viewModel.isSpeaking {
                return "Listening to speech"
            }
            return "Always-on listening is active."
        }
        if viewModel.connectionState == .connecting {
            return "Connecting to realtime translation"
        }
        return "Tap the mic to begin."
    }

    private var contextualHintSubtitle: String {
        if viewModel.connectionState == .connected {
            if viewModel.isOutputSpeaking {
                return "Speech output can be stopped anytime."
            }
            return "Auto-detects source language and translates to \(viewModel.language2.name)."
        }
        if viewModel.connectionState == .connecting {
            return "Initializing audio and network."
        }
        return "One tap to start. Speak naturally."
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
            if viewModel.isConnected {
                VADIndicatorView(isSpeaking: viewModel.isSpeaking)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            alwaysOnControl

            secondaryControlsRow
        }
    }

    private var alwaysOnControl: some View {
        VStack(spacing: 10) {
            if viewModel.isConnected {
                heroMicButton
            } else {
                Button {
                    Task { await startAlwaysOnSession() }
                } label: {
                    heroMicButton
                }
                .buttonStyle(SaphanPressableStyle(scale: 0.97))
                .disabled(viewModel.connectionState == .connecting)
            }

            if viewModel.isConnected && viewModel.isOutputSpeaking {
                Button {
                    Task { await viewModel.stopTranslationOutput() }
                } label: {
                    Text("Stop Output")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.accent)
                }
                .buttonStyle(SaphanPressableStyle(scale: 0.97))
            }
        }
        .padding(.vertical, 8)
    }

    private var heroMicButton: some View {
        ZStack {
            Circle()
                .fill(heroTint.opacity(0.16))
                .frame(width: 170, height: 170)

            Circle()
                .fill(heroTint.opacity(0.12))
                .frame(width: 132, height: 132)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [heroTint.opacity(0.96), heroTint.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 112, height: 112)
                .shadow(color: heroTint.opacity(0.35), radius: 18, y: 8)

            Image(systemName: heroIconName)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var heroTint: Color {
        viewModel.isConnected ? palette.accent : palette.warning
    }

    private var heroIconName: String {
        if viewModel.connectionState == .connecting {
            return "hourglass"
        }
        return viewModel.isConnected ? "waveform" : "mic"
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
    }

    private func startAlwaysOnSession() async {
        guard viewModel.connectionState != .connecting else { return }
        viewModel.interactionMode = .vad
        await viewModel.connect()
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
                            Text("\(language.nativeName) • \(language.code.uppercased())")
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
    @Binding var preferredLanguage: Language
    let targetLanguageCode: String
    @Binding var audioOutputPreference: AudioOutputPreference
    let currentOutputDeviceName: String
    @Binding var contextMode: ContextMode
    @Binding var selectedVoice: VoiceOption
    let onUpgradeTap: () -> Void
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
                        Text("Preferred Language")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.secondaryText)

                        Picker("Preferred language", selection: $preferredLanguage) {
                            ForEach(Language.allLanguages.filter { $0.code != targetLanguageCode }) { language in
                                Text("\(language.name) • \(language.nativeName)")
                                    .tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(14)
                    .background(cardBackground)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Audio Output")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.secondaryText)

                        Picker("Audio output", selection: $audioOutputPreference) {
                            ForEach(AudioOutputPreference.allCases) { output in
                                Text(output.title)
                                    .tag(output)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text("Current route: \(currentOutputDeviceName)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
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
                            Text("Unlock Memory, Export, Offline Packs")
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
