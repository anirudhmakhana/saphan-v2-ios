import Foundation

public enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case noAuthToken
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message)"
        case .noAuthToken:
            return "No authentication token found. Please sign in."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }

    public var statusCode: Int? {
        if case .httpError(let code, _) = self {
            return code
        }
        return nil
    }
}
