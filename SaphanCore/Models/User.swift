import Foundation

public struct User: Codable, Identifiable, Equatable {
    public let id: String
    public let email: String
    public let name: String?
    public let isGuest: Bool
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: String,
        email: String,
        name: String? = nil,
        isGuest: Bool = false,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.isGuest = isGuest
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case isGuest
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        isGuest = try container.decodeIfPresent(Bool.self, forKey: .isGuest) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(isGuest, forKey: .isGuest)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

public struct AuthResponse {
    public let token: String
    public let user: User
    public let refreshToken: String?

    public init(token: String, user: User, refreshToken: String? = nil) {
        self.token = token
        self.user = user
        self.refreshToken = refreshToken
    }
}
