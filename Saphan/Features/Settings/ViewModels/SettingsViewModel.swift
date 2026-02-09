import Foundation
import SwiftUI
import SaphanCore

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var defaultVoice: VoiceOption {
        didSet { PreferencesService.shared.defaultVoice = defaultVoice }
    }
    @Published var defaultContextMode: ContextMode {
        didSet { PreferencesService.shared.defaultContextMode = defaultContextMode }
    }
    @Published var defaultSourceLanguage: Language {
        didSet { PreferencesService.shared.defaultSourceLanguage = defaultSourceLanguage }
    }
    @Published var defaultTargetLanguage: Language {
        didSet { PreferencesService.shared.defaultTargetLanguage = defaultTargetLanguage }
    }
    @Published var defaultTone: Tone {
        didSet { PreferencesService.shared.defaultTone = defaultTone }
    }
    @Published var hapticsEnabled: Bool {
        didSet { PreferencesService.shared.hapticsEnabled = hapticsEnabled }
    }
    @Published var soundEffectsEnabled: Bool {
        didSet { PreferencesService.shared.soundEffectsEnabled = soundEffectsEnabled }
    }
    @Published var autoTranslateEnabled: Bool {
        didSet { PreferencesService.shared.autoTranslateEnabled = autoTranslateEnabled }
    }

    @Published var showingClearCacheAlert = false
    @Published var showingResetSettingsAlert = false
    @Published var isClearing = false

    private let preferences = PreferencesService.shared
    private let cacheService = CacheService()

    init() {
        defaultVoice = preferences.defaultVoice
        defaultContextMode = preferences.defaultContextMode
        defaultSourceLanguage = preferences.defaultSourceLanguage
        defaultTargetLanguage = preferences.defaultTargetLanguage
        defaultTone = preferences.defaultTone
        hapticsEnabled = preferences.hapticsEnabled
        soundEffectsEnabled = preferences.soundEffectsEnabled
        autoTranslateEnabled = preferences.autoTranslateEnabled
    }

    func clearCache() async {
        isClearing = true
        cacheService.clearCache()
        isClearing = false
        showingClearCacheAlert = false
    }

    func resetAllSettings() {
        preferences.resetToDefaults()
        defaultVoice = preferences.defaultVoice
        defaultContextMode = preferences.defaultContextMode
        defaultSourceLanguage = preferences.defaultSourceLanguage
        defaultTargetLanguage = preferences.defaultTargetLanguage
        defaultTone = preferences.defaultTone
        hapticsEnabled = preferences.hapticsEnabled
        soundEffectsEnabled = preferences.soundEffectsEnabled
        autoTranslateEnabled = preferences.autoTranslateEnabled
        showingResetSettingsAlert = false
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var availableVoices: [VoiceOption] { VoiceOption.allCases }
    var availableContextModes: [ContextMode] { ContextMode.allModes }
    var availableTones: [Tone] { Tone.allCases }
}
