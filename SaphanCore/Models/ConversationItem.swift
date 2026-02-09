import Foundation

public struct ConversationItem: Identifiable, Codable, Equatable {
    public let id: String
    public let role: Role
    public var text: String
    public let timestamp: Date

    public enum Role: String, Codable {
        case user
        case assistant
    }

    public init(id: String = UUID().uuidString, role: Role, text: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }

    public static func == (lhs: ConversationItem, rhs: ConversationItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.role == rhs.role &&
               lhs.text == rhs.text &&
               lhs.timestamp == rhs.timestamp
    }
}
