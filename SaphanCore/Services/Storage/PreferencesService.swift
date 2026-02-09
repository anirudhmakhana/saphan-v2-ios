import Foundation

public class PreferencesService {
    public static let shared = PreferencesService()

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = UserDefaults(suiteName: Constants.appGroupID) ?? .standard) {
        self.userDefaults = userDefaults
    }

    private enum Keys {
        static let sourceLanguage = "sourceLanguage"
        static let targetLanguage = "targetLanguage"
        static let defaultTone = "defaultTone"
        static let enableHaptics = "enableHaptics"
        static let enableSoundEffects = "enableSoundEffects"
        static let autoTranslate = "autoTranslate"
        static let saveHistory = "saveHistory"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let defaultContextMode = "defaultContextMode"
        static let selectedVoice = "selectedVoice"
        static let interactionMode = "interactionMode"
        static let subscriptionExpirationDate = "subscriptionExpirationDate"

        static var allKeys: [String] {
            return [
                sourceLanguage,
                targetLanguage,
                defaultTone,
                enableHaptics,
                enableSoundEffects,
                autoTranslate,
                saveHistory,
                hasCompletedOnboarding,
                defaultContextMode,
                selectedVoice,
                interactionMode,
                subscriptionExpirationDate
            ]
        }
    }

    public var sourceLanguage: Language {
        get {
            guard let id = userDefaults.string(forKey: Keys.sourceLanguage),
                  let language = Language.language(for: id) else {
                return Language.allLanguages.first { $0.id == "en" }!
            }
            return language
        }
        set {
            userDefaults.set(newValue.id, forKey: Keys.sourceLanguage)
        }
    }

    public var targetLanguage: Language {
        get {
            guard let id = userDefaults.string(forKey: Keys.targetLanguage),
                  let language = Language.language(for: id) else {
                return Language.allLanguages.first { $0.id == "es" }!
            }
            return language
        }
        set {
            userDefaults.set(newValue.id, forKey: Keys.targetLanguage)
        }
    }

    public var defaultTone: Tone {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.defaultTone),
                  let tone = Tone(rawValue: rawValue) else {
                return .neutral
            }
            return tone
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.defaultTone)
        }
    }

    public var defaultContextMode: ContextMode {
        get {
            guard let id = userDefaults.string(forKey: Keys.defaultContextMode),
                  let mode = ContextMode.mode(for: id) else {
                return .social
            }
            return mode
        }
        set {
            userDefaults.set(newValue.id, forKey: Keys.defaultContextMode)
        }
    }

    public var selectedVoice: VoiceOption {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.selectedVoice),
                  let voice = VoiceOption(rawValue: rawValue) else {
                return .alloy
            }
            return voice
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.selectedVoice)
        }
    }

    public var interactionMode: InteractionMode {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.interactionMode),
                  let mode = InteractionMode(rawValue: rawValue) else {
                return .ptt
            }
            return mode
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.interactionMode)
        }
    }

    public var enableHaptics: Bool {
        get {
            if userDefaults.object(forKey: Keys.enableHaptics) == nil {
                return true
            }
            return userDefaults.bool(forKey: Keys.enableHaptics)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.enableHaptics)
        }
    }

    public var enableSoundEffects: Bool {
        get {
            if userDefaults.object(forKey: Keys.enableSoundEffects) == nil {
                return true
            }
            return userDefaults.bool(forKey: Keys.enableSoundEffects)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.enableSoundEffects)
        }
    }

    public var autoTranslate: Bool {
        get {
            if userDefaults.object(forKey: Keys.autoTranslate) == nil {
                return false
            }
            return userDefaults.bool(forKey: Keys.autoTranslate)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.autoTranslate)
        }
    }

    public var saveHistory: Bool {
        get {
            if userDefaults.object(forKey: Keys.saveHistory) == nil {
                return true
            }
            return userDefaults.bool(forKey: Keys.saveHistory)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.saveHistory)
        }
    }

    public var hasCompletedOnboarding: Bool {
        get {
            userDefaults.bool(forKey: Keys.hasCompletedOnboarding)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
        }
    }

    public var subscriptionExpirationDate: Date? {
        get {
            userDefaults.object(forKey: Keys.subscriptionExpirationDate) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: Keys.subscriptionExpirationDate)
        }
    }

    public func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
    }

    public func reset() {
        Keys.self.allKeys.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
    }

    // Compatibility aliases used across app modules.
    public var defaultSourceLanguage: Language {
        get { sourceLanguage }
        set { sourceLanguage = newValue }
    }

    public var defaultTargetLanguage: Language {
        get { targetLanguage }
        set { targetLanguage = newValue }
    }

    public var defaultVoice: VoiceOption {
        get { selectedVoice }
        set { selectedVoice = newValue }
    }

    public var hapticsEnabled: Bool {
        get { enableHaptics }
        set { enableHaptics = newValue }
    }

    public var soundEffectsEnabled: Bool {
        get { enableSoundEffects }
        set { enableSoundEffects = newValue }
    }

    public var autoTranslateEnabled: Bool {
        get { autoTranslate }
        set { autoTranslate = newValue }
    }

    public func resetToDefaults() {
        reset()
    }
}
