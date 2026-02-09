import SwiftUI
import SaphanCore

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            List {
                voiceSettingsSection
                keyboardSettingsSection
                generalSettingsSection
                accountSection
                aboutSection
                dangerZoneSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var voiceSettingsSection: some View {
        Section {
            Picker("Default Voice", selection: $viewModel.defaultVoice) {
                ForEach(viewModel.availableVoices, id: \.self) { voice in
                    HStack {
                        Image(systemName: "waveform")
                        Text(voice.rawValue.capitalized)
                    }
                    .tag(voice)
                }
            }

            Picker("Default Context Mode", selection: $viewModel.defaultContextMode) {
                ForEach(viewModel.availableContextModes, id: \.self) { mode in
                    HStack {
                        Image(systemName: contextModeIcon(mode))
                        Text(mode.name)
                    }
                    .tag(mode)
                }
            }
        } header: {
            Label("Voice Settings", systemImage: "mic.fill")
        }
    }

    private var keyboardSettingsSection: some View {
        Section {
            NavigationLink {
                LanguagePairPickerView(
                    sourceLanguage: $viewModel.defaultSourceLanguage,
                    targetLanguage: $viewModel.defaultTargetLanguage
                )
            } label: {
                HStack {
                    Text("Default Language Pair")
                    Spacer()
                    Text("\(viewModel.defaultSourceLanguage.flag) \(viewModel.defaultTargetLanguage.flag)")
                        .foregroundColor(.secondary)
                }
            }

            Picker("Default Tone", selection: $viewModel.defaultTone) {
                ForEach(viewModel.availableTones, id: \.self) { tone in
                    HStack {
                        Image(systemName: toneIcon(tone))
                        Text(tone.rawValue.capitalized)
                    }
                    .tag(tone)
                }
            }
        } header: {
            Label("Keyboard Settings", systemImage: "keyboard.fill")
        }
    }

    private var generalSettingsSection: some View {
        Section {
            Toggle(isOn: $viewModel.hapticsEnabled) {
                Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
            }

            Toggle(isOn: $viewModel.soundEffectsEnabled) {
                Label("Sound Effects", systemImage: "speaker.wave.2.fill")
            }

            Toggle(isOn: $viewModel.autoTranslateEnabled) {
                Label("Auto-Translate", systemImage: "arrow.triangle.2.circlepath")
            }
        } header: {
            Label("General", systemImage: "gearshape.fill")
        } footer: {
            Text("Auto-translate starts translation immediately after you stop speaking")
        }
    }

    private var accountSection: some View {
        Section {
            if let user = authViewModel.currentUser {
                HStack {
                    Label("Email", systemImage: "envelope.fill")
                    Spacer()
                    Text(user.email)
                        .foregroundColor(.secondary)
                }

                if user.isGuest {
                    Button {
                        authViewModel.showSignUp = true
                    } label: {
                        Label("Create Account", systemImage: "person.badge.plus")
                            .foregroundColor(.blue)
                    }
                }
            }

            Button {
                showingPaywall = true
            } label: {
                Label("Upgrade to Pro", systemImage: "star.fill")
                    .foregroundColor(.purple)
            }

            Button(role: .destructive) {
                authViewModel.signOut()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } header: {
            Label("Account", systemImage: "person.fill")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Label("Version", systemImage: "info.circle.fill")
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .top) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text("About Saphan")
                        .font(.body)
                    Text("\"Saphan\" means bridge in Thai. We connect people across languages and cultures.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Link(destination: URL(string: "https://saphan.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            Link(destination: URL(string: "https://saphan.app/terms")!) {
                Label("Terms of Service", systemImage: "doc.text.fill")
            }
        } header: {
            Label("About", systemImage: "info.circle.fill")
        }
    }

    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.showingClearCacheAlert = true
            } label: {
                if viewModel.isClearing {
                    HStack {
                        ProgressView()
                        Text("Clearing Cache...")
                    }
                } else {
                    Label("Clear Cache", systemImage: "trash.fill")
                }
            }
            .disabled(viewModel.isClearing)
            .alert("Clear Cache", isPresented: $viewModel.showingClearCacheAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    Task {
                        await viewModel.clearCache()
                    }
                }
            } message: {
                Text("This will delete all cached translations and audio files.")
            }

            Button(role: .destructive) {
                viewModel.showingResetSettingsAlert = true
            } label: {
                Label("Reset All Settings", systemImage: "arrow.counterclockwise")
            }
            .alert("Reset Settings", isPresented: $viewModel.showingResetSettingsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetAllSettings()
                }
            } message: {
                Text("This will restore all settings to their default values.")
            }
        } header: {
            Label("Danger Zone", systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
        }
    }

    private func contextModeIcon(_ mode: ContextMode) -> String {
        mode.icon
    }

    private func toneIcon(_ tone: Tone) -> String {
        switch tone {
        case .casual: return "bubble.left.fill"
        case .neutral: return "bubble.middle.bottom.fill"
        case .formal: return "briefcase.fill"
        }
    }
}

struct LanguagePairPickerView: View {
    @Binding var sourceLanguage: Language
    @Binding var targetLanguage: Language
    @Environment(\.dismiss) private var dismiss

    private let allLanguages: [Language] = Language.allLanguages

    var body: some View {
        List {
            Section {
                Picker("From", selection: $sourceLanguage) {
                    ForEach(allLanguages, id: \.id) { language in
                        HStack {
                            Text(language.flag)
                            Text(language.name)
                        }
                        .tag(language)
                    }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("Source Language")
            }

            Section {
                Picker("To", selection: $targetLanguage) {
                    ForEach(allLanguages, id: \.id) { language in
                        HStack {
                            Text(language.flag)
                            Text(language.name)
                        }
                        .tag(language)
                    }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("Target Language")
            }
        }
        .navigationTitle("Language Pair")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
}
