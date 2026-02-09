import Foundation

public struct TranslationResponse: Codable {
    public let translatedText: String
    public let sourceLanguage: String
    public let targetLanguage: String
    public let detectedLanguage: String?
    public let confidence: Double?

    public init(translatedText: String, sourceLanguage: String, targetLanguage: String, detectedLanguage: String? = nil, confidence: Double? = nil) {
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.detectedLanguage = detectedLanguage
        self.confidence = confidence
    }
}

public enum TranslationError: Error, LocalizedError {
    case invalidInput
    case networkError
    case serverError(String)
    case rateLimitExceeded
    case unauthorized
    case quotaExceeded
    case unsupportedLanguage
    case unknown

    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input text"
        case .networkError:
            return "Network connection error"
        case .serverError(let message):
            return "Server error: \(message)"
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        case .unauthorized:
            return "Authentication required"
        case .quotaExceeded:
            return "Translation quota exceeded. Upgrade to continue."
        case .unsupportedLanguage:
            return "Language not supported"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
