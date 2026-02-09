import Foundation

public enum AuthError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidCredentials
    case missingSessionToken
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid authentication URL"
        case .invalidResponse:
            return "Invalid response from authentication service"
        case .invalidCredentials:
            return "Invalid email or password"
        case .missingSessionToken:
            return "Missing access token from authentication response"
        case .serverError(let message):
            return message
        }
    }
}

public final class AuthService {
    private let baseURL: String
    private let session: URLSession

    public init(baseURL: String = Constants.Backend.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func signIn(email: String, password: String) async throws -> AuthResponse {
        try await authenticate(path: "/auth/login", email: email, password: password)
    }

    public func signUp(email: String, password: String) async throws -> AuthResponse {
        try await authenticate(path: "/auth/signup", email: email, password: password)
    }

    public func signOut() {}

    private func authenticate(path: String, email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw AuthError.invalidURL
        }

        let payload = AuthPayload(email: email, password: password)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)
        request.timeoutInterval = Constants.API.timeout

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw AuthError.invalidCredentials
            }
            let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data)
            throw AuthError.serverError(errorResponse?.message ?? "Authentication failed")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let responseModel = try decoder.decode(AuthBackendResponse.self, from: data)

        guard let accessToken = responseModel.session?.accessToken else {
            throw AuthError.missingSessionToken
        }

        return AuthResponse(
            token: accessToken,
            user: responseModel.user,
            refreshToken: responseModel.session?.refreshToken
        )
    }
}

private struct AuthPayload: Codable {
    let email: String
    let password: String
}

private struct AuthBackendResponse: Codable {
    let user: User
    let session: AuthSession?
}

private struct AuthSession: Codable {
    let accessToken: String?
    let refreshToken: String?
}

private struct AuthErrorResponse: Codable {
    let error: String?
    let message: String?
}
