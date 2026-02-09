import Foundation

public struct ContextMode: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let icon: String
    public let description: String
    public let instructions: String

    public init(id: String, name: String, icon: String, description: String, instructions: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.instructions = instructions
    }
}

extension ContextMode {
    public static let dating = ContextMode(
        id: "dating",
        name: "Dating",
        icon: "heart.fill",
        description: "Romantic and charming conversations",
        instructions: "You are translating a romantic/dating conversation. Use warm, charming language. Preserve flirtatious undertones. Use culturally appropriate terms of endearment. Keep the emotional warmth in translation."
    )

    public static let social = ContextMode(
        id: "social",
        name: "Social",
        icon: "person.2.fill",
        description: "Casual and friendly chats",
        instructions: "You are translating a casual social conversation. Use natural, relaxed language. Humor and slang should be adapted culturally, not translated literally. Keep it light and fun."
    )

    public static let business = ContextMode(
        id: "business",
        name: "Business",
        icon: "briefcase.fill",
        description: "Professional and polished",
        instructions: "You are translating a professional/business conversation. Use formal, polished language. Maintain professional courtesy. Use industry-appropriate terminology. Preserve the authoritative tone."
    )

    public static let travel = ContextMode(
        id: "travel",
        name: "Travel",
        icon: "airplane",
        description: "Helpful travel phrases",
        instructions: "You are translating a travel-related conversation. Be clear and helpful. Use common phrases locals would understand. Include relevant cultural context. Prioritize clarity over style."
    )

    public static let emergency = ContextMode(
        id: "emergency",
        name: "Emergency",
        icon: "exclamationmark.triangle.fill",
        description: "Clear and urgent communication",
        instructions: "You are translating an emergency/urgent conversation. Be extremely clear and direct. Use simple, unambiguous language. Prioritize speed and accuracy. No pleasantries - get the message across immediately."
    )

    public static let allModes: [ContextMode] = [
        .social,
        .dating,
        .business,
        .travel,
        .emergency
    ]

    public static func mode(for id: String) -> ContextMode? {
        return allModes.first { $0.id == id }
    }
}
