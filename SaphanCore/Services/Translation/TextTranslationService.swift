import Foundation

public class TranslationService {
    private let baseURL: String
    private let session: URLSession
    private let cacheService: CacheService
    private let keychainService: KeychainService

    public init(
        baseURL: String = Constants.Backend.baseURL,
        session: URLSession = .shared,
        cacheService: CacheService = CacheService(),
        keychainService: KeychainService = KeychainService()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.cacheService = cacheService
        self.keychainService = keychainService
    }

    public func translate(_ request: TranslationRequest) async throws -> TranslationResponse {
        if let cachedResponse = cacheService.getCachedTranslation(for: request.cacheKey) {
            return cachedResponse
        }

        guard let authToken = keychainService.getAuthToken(), !authToken.isEmpty else {
            throw TranslationError.unauthorized
        }

        guard let url = URL(string: "\(baseURL)/translate") else {
            throw TranslationError.networkError
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = Constants.API.timeout
        urlRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.networkError
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let translationResponse = try decoder.decode(TranslationResponse.self, from: data)
                cacheService.cacheTranslation(translationResponse, for: request.cacheKey)
                return translationResponse
            } catch {
                throw TranslationError.serverError("Failed to decode response")
            }
        case 404:
            throw TranslationError.serverError("Translation endpoint is not deployed on the backend")
        case 401:
            throw TranslationError.unauthorized
        case 429:
            throw TranslationError.rateLimitExceeded
        case 403:
            throw TranslationError.quotaExceeded
        case 400:
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TranslationError.serverError(errorResponse.message)
            }
            throw TranslationError.invalidInput
        default:
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw TranslationError.serverError(errorResponse.message)
            }
            throw TranslationError.unknown
        }
    }

    public func clearCache() {
        cacheService.clearCache()
    }
}

private struct ErrorResponse: Codable {
    let message: String
}
