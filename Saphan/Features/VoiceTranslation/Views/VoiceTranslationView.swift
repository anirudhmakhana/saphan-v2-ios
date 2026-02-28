import SwiftUI
import SaphanCore

// MARK: - Orb State

enum OrbState: Equatable {
    case idle
    case connecting
    case listening
    case translating
    case speaking

    var glowColor: Color {
        switch self {
        case .idle, .connecting:
            return Color(red: 0.22, green: 0.55, blue: 0.60)   // teal
        case .listening:
            return Color(red: 0.878, green: 0.471, blue: 0.337) // coral
        case .translating:
            return Color(red: 0.867, green: 0.643, blue: 0.278) // amber
        case .speaking:
            return Color(red: 0.200, green: 0.780, blue: 0.349) // green
        }
    }

    var statusDotColor: Color {
        switch self {
        case .idle:        return .white.opacity(0.30)
        case .connecting:  return Color(red: 0.867, green: 0.643, blue: 0.278)
        case .listening:   return Color(red: 0.878, green: 0.471, blue: 0.337)
        case .translating: return Color(red: 0.867, green: 0.643, blue: 0.278)
        case .speaking:    return Color(red: 0.200, green: 0.780, blue: 0.349)
        }
    }

    var statusText: String {
        switch self {
        case .idle:        return "Idle"
        case .connecting:  return "Connecting"
        case .listening:   return "Listening"
        case .translating: return "Translating"
        case .speaking:    return "Speaking"
        }
    }

    var orbIcon: String {
        switch self {
        case .idle, .connecting: return "mic.fill"
        case .listening:         return "waveform"
        case .translating:       return "waveform.badge.microphone"
        case .speaking:          return "speaker.wave.2.fill"
        }
    }
}

// MARK: - Blob Shape

/// Smooth organic blob that morphs continuously via a phase offset.
struct BlobShape: Shape {
    var phase: Double

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let base = min(rect.width, rect.height) / 2 * 0.80
        let count = 6

        // Compute 6 points around a circle with sine-modulated radii
        var pts: [CGPoint] = []
        for i in 0..<count {
            let angle = Double(i) / Double(count) * .pi * 2 - .pi / 2
            let noise =
                sin(Double(i) * 1.73 + phase * .pi * 2) * 0.14 +
                sin(Double(i) * 3.10 + phase * .pi * 1.47) * 0.07
            let r = base * CGFloat(1.0 + noise)
            pts.append(CGPoint(
                x: cx + r * CGFloat(cos(angle)),
                y: cy + r * CGFloat(sin(angle))
            ))
        }

        // Smooth closed path using Catmull-Rom → cubic Bezier tangents
        let n = pts.count
        var path = Path()
        path.move(to: pts[0])
        for i in 0..<n {
            let p0 = pts[(i - 1 + n) % n]
            let p1 = pts[i]
            let p2 = pts[(i + 1) % n]
            let p3 = pts[(i + 2) % n]
            let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6,
                              y: p1.y + (p2.y - p0.y) / 6)
            let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6,
                              y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Voice Orb View

struct VoiceOrbView: View {
    let state: OrbState
    let time: TimeInterval   // raw system time → drives blob morph
    let amplitude: Double    // 0…1 → drives scale reactivity

    private var blobPhase: Double { time * 0.22 }
    private var glowColor: Color   { state.glowColor }
    private var orbScale: CGFloat  { 1.0 + CGFloat(amplitude) * 0.14 }

    var body: some View {
        ZStack {
            // Outer diffuse glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [glowColor.opacity(0.28), glowColor.opacity(0.06), .clear],
                        center: .center,
                        startRadius: 40,
                        endRadius: 115
                    )
                )
                .frame(width: 240, height: 240)
                .blur(radius: 14)

            // Aura ring
            Circle()
                .fill(glowColor.opacity(0.10))
                .frame(width: 178, height: 178)
                .blur(radius: 6)

            // Morphing blob core
            BlobShape(phase: blobPhase)
                .fill(
                    LinearGradient(
                        colors: [
                            glowColor.opacity(0.92),
                            glowColor.opacity(0.58)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 148, height: 148)
                .scaleEffect(orbScale)
                .animation(.linear(duration: 0.06), value: amplitude)

            // Specular highlight (top-left shimmer)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.24), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 44
                    )
                )
                .frame(width: 76, height: 52)
                .offset(x: -16, y: -24)
                .allowsHitTesting(false)

            // State icon
            Image(systemName: state.orbIcon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))
        }
        .animation(SaphanMotion.smoothSpring, value: glowColor)
    }
}

// MARK: - Voice Translation View

struct VoiceTranslationView: View {
    @StateObject private var viewModel = VoiceTranslationViewModel()
    @EnvironmentObject private var subscriptionViewModel: SubscriptionViewModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var showPaywall = false
    @State private var showAdvancedControls = false
    @State private var showConversationHistory = false

    // MARK: Computed helpers

    private var orbState: OrbState {
        switch viewModel.connectionState {
        case .connected:
            if viewModel.isOutputSpeaking { return .speaking }
            if viewModel.isTranslating    { return .translating }
            return .listening
        case .connecting:
            return .connecting
        case .disconnected, .error:
            return .idle
        @unknown default:
            return .idle
        }
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

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            atmosphericBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                languageSwitcher
                    .padding(.horizontal, 32)
                    .padding(.top, 8)

                Spacer(minLength: 24)

                // Animated voice orb driven by system clock
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { tl in
                    VoiceOrbView(
                        state: orbState,
                        time: tl.date.timeIntervalSinceReferenceDate,
                        amplitude: viewModel.isSpeaking ? 1.0 : 0.0
                    )
                }
                .frame(width: 240, height: 240)

                contextModePill
                    .padding(.top, 18)

                Spacer(minLength: 24)

                transcriptView
                    .frame(maxHeight: 180)
                    .padding(.horizontal, 28)

                floatingActionBar
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                if viewModel.isConnected {
                    Text(viewModel.sessionDurationFormatted)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.28))
                        .padding(.bottom, 10)
                        .transition(.opacity.animation(.easeIn(duration: 0.5).delay(0.4)))
                }
            }
        }
        .animation(SaphanMotion.smoothSpring, value: orbState)
        .animation(SaphanMotion.smoothSpring, value: viewModel.isConnected)
        .animation(SaphanMotion.smoothSpring, value: viewModel.history.count)
        // Sheets
        .sheet(isPresented: $viewModel.showLanguage1Picker) {
            LanguagePickerSheet(
                selectedLanguage: $viewModel.language1,
                title: "Your language",
                excludedLanguageCode: viewModel.language2.code
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showLanguage2Picker) {
            LanguagePickerSheet(
                selectedLanguage: $viewModel.language2,
                title: "Translate to",
                excludedLanguageCode: viewModel.language1.code
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAdvancedControls) {
            AdvancedTranslationControlsSheet(
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
                selectedVoice: $viewModel.selectedVoice
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
                    Task { await subscriptionViewModel.checkSubscriptionStatus() }
                }
        }
        .alert("Translation Error", isPresented: errorAlertBinding) {
            Button("Dismiss", role: .cancel) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "Unknown error")
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background && viewModel.isConnected {
                Task { await viewModel.disconnect() }
            } else if newPhase == .active {
                Task {
                    await subscriptionViewModel.checkSubscriptionStatus()
                    viewModel.warmupRealtimeIfNeeded()
                }
            }
        }
        .onAppear {
            Task {
                await subscriptionViewModel.checkSubscriptionStatus()
                viewModel.warmupRealtimeIfNeeded()
            }
        }
    }

    // MARK: - Background

    private var atmosphericBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 14/255, green: 15/255, blue: 16/255),
                Color(red: 20/255, green: 19/255, blue: 18/255),
                Color(red: 26/255, green: 24/255, blue: 22/255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            statusPill
            Spacer()
            settingsButton
        }
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(orbState.statusDotColor)
                .frame(width: 6, height: 6)
                .shadow(color: orbState.statusDotColor.opacity(0.80), radius: 4)
            Text(orbState.statusText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.white.opacity(0.07), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))
    }

    private var settingsButton: some View {
        Button {
            showAdvancedControls = true
            HapticManager.selection()
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.60))
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.07), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(SaphanPressableStyle(scale: 0.94))
    }

    // MARK: - Language Switcher

    private var languageSwitcher: some View {
        HStack(spacing: 0) {
            // Source language
            Button {
                viewModel.showLanguage1Picker = true
                HapticManager.selection()
            } label: {
                VStack(spacing: 3) {
                    Text(viewModel.language1.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("From")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.38))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaphanPressableStyle(scale: 0.96))

            // Swap button
            Button {
                let tmp = viewModel.language1
                viewModel.updateLanguage1(viewModel.language2)
                viewModel.language2 = tmp
                HapticManager.impact(.light)
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.09), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(SaphanPressableStyle(scale: 0.90))
            .disabled(viewModel.isConnected)

            // Target language
            Button {
                viewModel.showLanguage2Picker = true
                HapticManager.selection()
            } label: {
                VStack(spacing: 3) {
                    Text(viewModel.language2.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(SaphanTheme.brandCoral)
                        .lineLimit(1)
                    Text("To")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.38))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaphanPressableStyle(scale: 0.96))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        )
    }

    // MARK: - Context Mode Pill

    private var contextModePill: some View {
        Button {
            showAdvancedControls = true
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel.contextMode.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(viewModel.contextMode.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.50))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.white.opacity(0.07), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(SaphanPressableStyle(scale: 0.96))
    }

    // MARK: - Transcript

    private var transcriptView: some View {
        Group {
            if latestSourceTranscript == nil && latestTranslation == nil {
                if !viewModel.isConnected && viewModel.connectionState != .connecting {
                    Text("Tap to begin translating")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.28))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        if let source = latestSourceTranscript {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("YOU SAID")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.28))
                                    .tracking(0.8)
                                Text(source)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.75))
                                    .textSelection(.enabled)
                            }
                        }
                        if let translation = latestTranslation {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.language2.name.uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(SaphanTheme.brandCoral.opacity(0.65))
                                    .tracking(0.8)
                                Text(translation)
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                    .foregroundStyle(SaphanTheme.brandCoral)
                                    .textSelection(.enabled)
                            }
                        }
                        if exchangeCount > 1 {
                            Button {
                                showConversationHistory = true
                                HapticManager.selection()
                            } label: {
                                Text("View \(exchangeCount) exchanges →")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.28))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.10),
                            .init(color: .black, location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }

    // MARK: - Floating Action Bar

    private var floatingActionBar: some View {
        HStack {
            // Left: Conversation history
            Button {
                showConversationHistory = true
                HapticManager.selection()
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(exchangeCount > 0 ? 0.65 : 0.25))
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.08), in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(SaphanPressableStyle(scale: 0.94))
            .disabled(exchangeCount == 0)

            Spacer()

            // Center: Hero mic button
            heroButton

            Spacer()

            // Right: End session (when connected) or empty placeholder
            if viewModel.isConnected {
                Button {
                    Task { await viewModel.disconnect() }
                    HapticManager.impact(.medium)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.65))
                        .frame(width: 46, height: 46)
                        .background(.white.opacity(0.08), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(SaphanPressableStyle(scale: 0.94))
            } else {
                // Spacer placeholder to keep hero centered
                Circle()
                    .fill(.clear)
                    .frame(width: 46, height: 46)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var heroButton: some View {
        Group {
            if viewModel.isConnected {
                heroButtonInner
                    .onTapGesture {
                        // While connected, hero button stops output if speaking, else no-op (use X to end)
                        if viewModel.isOutputSpeaking {
                            Task { await viewModel.stopTranslationOutput() }
                        }
                        HapticManager.impact(.soft)
                    }
            } else {
                Button {
                    Task { await startAlwaysOnSession() }
                } label: {
                    heroButtonInner
                }
                .buttonStyle(SaphanPressableStyle(scale: 0.96))
                .disabled(viewModel.connectionState == .connecting)
            }
        }
    }

    private var heroButtonInner: some View {
        ZStack {
            Circle()
                .fill(heroButtonBackground)
                .frame(width: 72, height: 72)
                .shadow(color: heroButtonBackground.opacity(0.45), radius: 18, y: 6)

            Image(systemName: heroIconName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(heroIconColor)
        }
    }

    private var heroButtonBackground: Color {
        switch viewModel.connectionState {
        case .connected:   return SaphanTheme.brandCoral
        case .connecting:  return .white.opacity(0.20)
        default:           return .white
        }
    }

    private var heroIconColor: Color {
        switch viewModel.connectionState {
        case .connected:   return .white
        case .connecting:  return .white.opacity(0.60)
        default:           return .black
        }
    }

    private var heroIconName: String {
        switch viewModel.connectionState {
        case .connecting:
            return "hourglass"
        case .connected:
            if viewModel.isOutputSpeaking { return "speaker.slash.fill" }
            return "waveform"
        default:
            return "mic.fill"
        }
    }

    // MARK: - Actions

    private func startAlwaysOnSession() async {
        guard viewModel.connectionState != .connecting else { return }
        await subscriptionViewModel.checkSubscriptionStatus()
        guard subscriptionViewModel.isSubscribed else {
            showPaywall = true
            HapticManager.selection()
            return
        }
        viewModel.interactionMode = .vad
        await viewModel.connect()
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
                            Text("\(language.nativeName) · \(language.code.uppercased())")
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
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Feature Row

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

// MARK: - Advanced Controls Sheet

struct AdvancedTranslationControlsSheet: View {
    @Binding var preferredLanguage: Language
    let targetLanguageCode: String
    @Binding var audioOutputPreference: AudioOutputPreference
    let currentOutputDeviceName: String
    @Binding var contextMode: ContextMode
    @Binding var selectedVoice: VoiceOption
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
                                Text("\(language.name) · \(language.nativeName)")
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
                                Text(output.title).tag(output)
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
                                Text(voice.rawValue.capitalized).tag(voice)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(14)
                    .background(cardBackground)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tone Context")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.secondaryText)
                        ContextModePicker(selectedMode: $contextMode, isEnabled: true)
                    }
                    .padding(14)
                    .background(cardBackground)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 18)
            }
            .navigationTitle("Advanced Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
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

// MARK: - Preview

#Preview {
    VoiceTranslationView()
        .environmentObject(SubscriptionViewModel())
}
