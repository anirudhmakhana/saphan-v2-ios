import Foundation
import CryptoKit

public struct TranslationRequest: Codable {
    public let text: String
    public let sourceLanguage: String
    public let targetLanguage: String
    public let tone: String
    public let mode: TranslationMode

    public init(text: String, sourceLanguage: String, targetLanguage: String, tone: String = "neutral", mode: TranslationMode = .standard) {
        self.text = text
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.tone = tone
        self.mode = mode
    }

    public var cacheKey: String {
        let components = "\(text)|\(sourceLanguage)|\(targetLanguage)|\(tone)|\(mode.rawValue)"
        return components.sha256Hash
    }
}

public enum TranslationMode: String, Codable {
    case standard
    case contextual
}

extension String {
    var sha256Hash: String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
