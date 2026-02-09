import SwiftUI
import SaphanCore

/// Main voice translation screen
struct VoiceTranslationView: View {
    @StateObject private var viewModel = VoiceTranslationViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    private var palette: VoiceTranslationTheme.Palette {
        VoiceTranslationTheme.palette(for: colorScheme)
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

    var body: some View {
        ZStack {
            VoiceTranslationTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                headerSection
                configurationSection
                conversationSection
                controlSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
        }
        .sheet(isPresented: $viewModel.showLanguage1Picker) {
            LanguagePickerSheet(
                selectedLanguage: $viewModel.language1,
                title: "Choose source language"
            )
        }
        .sheet(isPresented: $viewModel.showLanguage2Picker) {
            LanguagePickerSheet(
                selectedLanguage: $viewModel.language2,
                title: "Choose target language"
            )
        }
        .sheet(isPresented: $viewModel.showVoicePicker) {
            VoicePickerSheet(selectedVoice: $viewModel.selectedVoice)
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
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Live Translate")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.primaryText)

                Text("Real-time voice. Context-aware tone.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.secondaryText)
            }

            Spacer(minLength: 8)

            Button {
                viewModel.showVoicePicker = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 21))
                    Text("Voice")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(palette.accent)
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(palette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.stroke.opacity(0.85), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isConnected)
            .opacity(viewModel.isConnected ? 0.55 : 1.0)
        }
    }

    private var configurationSection: some View {
        VStack(spacing: 12) {
            SessionTimerView(
                duration: viewModel.sessionDurationFormatted,
                connectionState: viewModel.connectionState
            )

            LanguageSelectorView(
                language1: viewModel.language1,
                language2: viewModel.language2,
                onLanguage1Tap: { viewModel.showLanguage1Picker = true },
                onLanguage2Tap: { viewModel.showLanguage2Picker = true },
                onSwapTap: { viewModel.swapLanguages() }
            )

            ContextModePicker(
                selectedMode: $viewModel.contextMode,
                isEnabled: !viewModel.isConnected
            )
        }
        .padding(14)
        .background(cardBackground)
    }

    private var conversationSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Conversation")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                    Text("Live transcript and translated responses")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                }

                Spacer()

                if !viewModel.history.isEmpty {
                    Button("Clear") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.clearHistory()
                        }
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.accent)
                }
            }
            .padding(.bottom, 10)

            Divider()
                .overlay(palette.stroke.opacity(0.7))
                .padding(.bottom, 8)

            if viewModel.history.isEmpty {
                emptyHistoryView
            } else {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.history) { item in
                                ConversationBubbleView(item: item)
                                    .id(item.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: viewModel.history.count) { _ in
                        guard let lastItem = viewModel.history.last else { return }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            proxy.scrollTo(lastItem.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxHeight: .infinity)
        .background(cardBackground)
    }

    private var emptyHistoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 34))
                .foregroundStyle(palette.secondaryText.opacity(0.8))

            Text(viewModel.isConnected ? "Start speaking to begin translation." : "Connect to start a live session.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 20)
    }

    private var controlSection: some View {
        VStack(spacing: 12) {
            if viewModel.isConnected {
                interactionModeToggle
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                Group {
                    if viewModel.interactionMode == .ptt {
                        PTTButtonView(
                            isActive: viewModel.isPTTActive,
                            isSpeaking: viewModel.isSpeaking,
                            onPressDown: { viewModel.pttPressed() },
                            onPressUp: { viewModel.pttReleased() }
                        )
                    } else {
                        VADIndicatorView(isSpeaking: viewModel.isSpeaking)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

            connectButton
        }
        .padding(14)
        .background(cardBackground)
        .animation(.spring(response: 0.35, dampingFraction: 0.84), value: viewModel.isConnected)
        .animation(.spring(response: 0.35, dampingFraction: 0.84), value: viewModel.interactionMode)
    }

    private var interactionModeToggle: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Input Mode")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.secondaryText)

            HStack(spacing: 8) {
                ForEach(InteractionMode.allCases) { mode in
                    let isSelected = viewModel.interactionMode == mode
                    Button {
                        guard viewModel.interactionMode != mode else { return }
                        viewModel.interactionMode = mode
                        viewModel.toggleInteractionMode()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 13, weight: .semibold))
                            Text(mode == .ptt ? "Push" : "Auto")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(isSelected ? Color.white : palette.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? palette.accent : palette.elevatedSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? palette.accent.opacity(0.4) : palette.stroke.opacity(0.8), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var connectButton: some View {
        Button {
            Task {
                await viewModel.toggleConnection()
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 34, height: 34)

                    if case .connecting = viewModel.connectionState {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.82)
                    } else {
                        Image(systemName: connectButtonIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.connectionButtonTitle)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text(connectButtonSubtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .opacity(0.82)
                }
                .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 62)
            .background(connectButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: connectShadowColor, radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isConnecting)
        .opacity(isConnecting ? 0.85 : 1.0)
    }

    private var connectButtonIcon: String {
        switch viewModel.connectionState {
        case .connected:
            return "stop.fill"
        case .connecting:
            return "arrow.clockwise"
        case .disconnected:
            return "play.fill"
        case .error:
            return "arrow.trianglehead.clockwise"
        }
    }

    private var connectButtonSubtitle: String {
        switch viewModel.connectionState {
        case .disconnected:
            return "Start real-time conversation"
        case .connecting:
            return "Preparing microphone and agent"
        case .connected:
            return "Tap to end this session"
        case .error:
            return "Try reconnecting now"
        }
    }

    @ViewBuilder
    private var connectButtonBackground: some View {
        switch viewModel.connectionState {
        case .connected:
            VoiceTranslationTheme.destructiveCTA(for: colorScheme)
        default:
            VoiceTranslationTheme.primaryCTA(for: colorScheme)
        }
    }

    private var connectShadowColor: Color {
        switch viewModel.connectionState {
        case .connected:
            return palette.danger.opacity(0.35)
        default:
            return palette.accent.opacity(0.33)
        }
    }

    private var isConnecting: Bool {
        viewModel.connectionState == .connecting
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(palette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(palette.stroke.opacity(0.85), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.08), radius: 14, y: 7)
    }
}

// MARK: - Language Picker Sheet
struct LanguagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLanguage: Language
    let title: String

    var body: some View {
        NavigationView {
            List(Language.allLanguages) { language in
                Button {
                    selectedLanguage = language
                    dismiss()
                } label: {
                    HStack(spacing: 10) {
                        Text(language.flag)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(language.name)
                                .foregroundStyle(.primary)
                            Text(language.nativeName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if language.code == selectedLanguage.code {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
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

// MARK: - Voice Picker Sheet
struct VoicePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedVoice: VoiceOption

    var body: some View {
        NavigationView {
            List(VoiceOption.allCases) { voice in
                Button {
                    selectedVoice = voice
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
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
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

    private var palette: VoiceTranslationTheme.Palette {
        VoiceTranslationTheme.palette(for: colorScheme)
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
