import Foundation

public struct TokenResponse: Decodable {
    public let token: String

    private struct DynamicCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)

        func decodeString(for key: String) -> String? {
            guard let codingKey = DynamicCodingKey(stringValue: key),
                  let value = try? container.decode(String.self, forKey: codingKey),
                  !value.isEmpty else {
                return nil
            }
            return value
        }

        // Supported top-level token formats:
        // - { "token": "..." }
        // - { "value": "..." }
        // - { "client_secret": "..." }
        // - { "ephemeral_token": "..." }
        if let directToken = decodeString(for: "token")
            ?? decodeString(for: "value")
            ?? decodeString(for: "client_secret")
            ?? decodeString(for: "clientSecret")
            ?? decodeString(for: "ephemeral_token")
            ?? decodeString(for: "ephemeralToken") {
            self.token = directToken
            return
        }

        // Supported nested formats:
        // - { "client_secret": { "value": "..." } }
        // - { "clientSecret": { "value": "..." } }
        for parentKeyName in ["client_secret", "clientSecret"] {
            guard let parentKey = DynamicCodingKey(stringValue: parentKeyName),
                  let nested = try? container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: parentKey) else {
                continue
            }

            if let valueKey = DynamicCodingKey(stringValue: "value"),
               let value = try? nested.decode(String.self, forKey: valueKey),
               !value.isEmpty {
                self.token = value
                return
            }

            if let tokenKey = DynamicCodingKey(stringValue: "token"),
               let value = try? nested.decode(String.self, forKey: tokenKey),
               !value.isEmpty {
                self.token = value
                return
            }
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "No ephemeral token found in /token response."
            )
        )
    }
}

public struct SubscriptionResponse: Codable {
    public let usage: UsageInfo
    public let subscription: SubscriptionInfo?

    public struct UsageInfo: Codable {
        public let minutesUsed: Double
        public let minutesRemaining: Double
        public let quotaLimit: Double
        public let totalSessions: Int
        public let sessionsThisMonth: Int?
    }

    public struct SubscriptionInfo: Codable {
        public let isActive: Bool?
    }
}

public struct SessionRecordRequest: Codable {
    public let languageFrom: String
    public let languageTo: String
    public let contextMode: String
    public let toneLevel: Int
    public let durationSeconds: Int

    public init(languageFrom: String, languageTo: String, contextMode: String, toneLevel: Int, durationSeconds: Int) {
        self.languageFrom = languageFrom
        self.languageTo = languageTo
        self.contextMode = contextMode
        self.toneLevel = toneLevel
        self.durationSeconds = durationSeconds
    }
}

public class APIClient {
    public static let shared = APIClient()

    private let baseURL: String
    private let session: URLSession
    private let keychainService: KeychainService

    public init(baseURL: String = Constants.Backend.baseURL, session: URLSession = .shared, keychainService: KeychainService = KeychainService()) {
        self.baseURL = baseURL
        self.session = session
        self.keychainService = keychainService
    }

    public func getEphemeralToken(voice: String? = nil, instructions: String? = nil) async throws -> TokenResponse {
        guard var urlComponents = URLComponents(string: "\(baseURL)/token") else {
            throw APIError.invalidURL
        }

        var queryItems: [URLQueryItem] = []
        if let voice = voice {
            queryItems.append(URLQueryItem(name: "voice", value: voice))
        }
        if let instructions = instructions {
            queryItems.append(URLQueryItem(name: "instructions", value: instructions))
        }
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try addAuthHeaders(to: &request)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        do {
            let tokenResponse = try decoder().decode(TokenResponse.self, from: data)
            return tokenResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }

    public func getSubscription() async throws -> SubscriptionResponse {
        guard let url = URL(string: "\(baseURL)/user/subscription") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try addAuthHeaders(to: &request)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        do {
            let subscriptionResponse = try decoder().decode(SubscriptionResponse.self, from: data)
            return subscriptionResponse
        } catch {
            throw APIError.decodingError(error)
        }
    }

    public func recordSession(languageFrom: String, languageTo: String, contextMode: String, toneLevel: Int = 0, durationSeconds: Int) async throws {
        guard let url = URL(string: "\(baseURL)/history/session") else {
            throw APIError.invalidURL
        }

        let requestBody = SessionRecordRequest(
            languageFrom: languageFrom,
            languageTo: languageTo,
            contextMode: contextMode,
            toneLevel: toneLevel,
            durationSeconds: durationSeconds
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try addAuthHeaders(to: &request)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }

    private func addAuthHeaders(to request: inout URLRequest) throws {
        guard let token = keychainService.getAuthToken() else {
            throw APIError.noAuthToken
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
