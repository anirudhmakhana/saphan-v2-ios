import Foundation

public struct Language: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let nativeName: String
    public let flag: String
    public let code: String

    public init(id: String, name: String, nativeName: String, flag: String, code: String) {
        self.id = id
        self.name = name
        self.nativeName = nativeName
        self.flag = flag
        self.code = code
    }
}

extension Language {
    public static let allLanguages: [Language] = [
        Language(id: "en", name: "English", nativeName: "English", flag: "🇺🇸", code: "en"),
        Language(id: "es", name: "Spanish", nativeName: "Español", flag: "🇪🇸", code: "es"),
        Language(id: "fr", name: "French", nativeName: "Français", flag: "🇫🇷", code: "fr"),
        Language(id: "de", name: "German", nativeName: "Deutsch", flag: "🇩🇪", code: "de"),
        Language(id: "it", name: "Italian", nativeName: "Italiano", flag: "🇮🇹", code: "it"),
        Language(id: "pt", name: "Portuguese", nativeName: "Português", flag: "🇵🇹", code: "pt"),
        Language(id: "ja", name: "Japanese", nativeName: "日本語", flag: "🇯🇵", code: "ja"),
        Language(id: "ko", name: "Korean", nativeName: "한국어", flag: "🇰🇷", code: "ko"),
        Language(id: "zh-cmn", name: "Mandarin", nativeName: "普通话", flag: "🇨🇳", code: "zh-cmn"),
        Language(id: "zh-yue", name: "Cantonese", nativeName: "廣東話", flag: "🇭🇰", code: "zh-yue"),
        Language(id: "ru", name: "Russian", nativeName: "Русский", flag: "🇷🇺", code: "ru"),
        Language(id: "hi", name: "Hindi", nativeName: "हिन्दी", flag: "🇮🇳", code: "hi"),
        Language(id: "ar", name: "Arabic", nativeName: "العربية", flag: "🇸🇦", code: "ar"),
        Language(id: "th", name: "Thai", nativeName: "ไทย", flag: "🇹🇭", code: "th"),
        Language(id: "vi", name: "Vietnamese", nativeName: "Tiếng Việt", flag: "🇻🇳", code: "vi"),
        Language(id: "pl", name: "Polish", nativeName: "Polski", flag: "🇵🇱", code: "pl")
    ]

    public static let keyboardLanguages: [Language] = [
        Language(id: "en", name: "English", nativeName: "English", flag: "🇺🇸", code: "en"),
        Language(id: "es", name: "Spanish", nativeName: "Español", flag: "🇪🇸", code: "es"),
        Language(id: "fr", name: "French", nativeName: "Français", flag: "🇫🇷", code: "fr"),
        Language(id: "de", name: "German", nativeName: "Deutsch", flag: "🇩🇪", code: "de"),
        Language(id: "it", name: "Italian", nativeName: "Italiano", flag: "🇮🇹", code: "it"),
        Language(id: "pt", name: "Portuguese", nativeName: "Português", flag: "🇵🇹", code: "pt"),
        Language(id: "ja", name: "Japanese", nativeName: "日本語", flag: "🇯🇵", code: "ja"),
        Language(id: "ko", name: "Korean", nativeName: "한국어", flag: "🇰🇷", code: "ko"),
        Language(id: "zh-cmn", name: "Mandarin", nativeName: "普通话", flag: "🇨🇳", code: "zh-cmn"),
        Language(id: "th", name: "Thai", nativeName: "ไทย", flag: "🇹🇭", code: "th"),
        Language(id: "vi", name: "Vietnamese", nativeName: "Tiếng Việt", flag: "🇻🇳", code: "vi"),
        Language(id: "pl", name: "Polish", nativeName: "Polski", flag: "🇵🇱", code: "pl")
    ]

    public static func language(for id: String) -> Language? {
        return allLanguages.first { $0.id == id }
    }

    public static var english: Language { language(for: "en")! }
    public static var spanish: Language { language(for: "es")! }
    public static var french: Language { language(for: "fr")! }
    public static var german: Language { language(for: "de")! }
    public static var italian: Language { language(for: "it")! }
    public static var portuguese: Language { language(for: "pt")! }
    public static var japanese: Language { language(for: "ja")! }
    public static var korean: Language { language(for: "ko")! }
    public static var chinese: Language { language(for: "zh-cmn")! }
    public static var thai: Language { language(for: "th")! }
    public static var vietnamese: Language { language(for: "vi")! }
    public static var polish: Language { language(for: "pl")! }
}

public struct LanguagePair: Codable, Hashable {
    public let source: Language
    public let target: Language

    public init(source: Language, target: Language) {
        self.source = source
        self.target = target
    }

    public var reversed: LanguagePair {
        return LanguagePair(source: target, target: source)
    }
}
