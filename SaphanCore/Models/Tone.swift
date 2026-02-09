import Foundation

public enum Tone: String, Codable, CaseIterable, Identifiable {
    case casual
    case neutral
    case formal

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .casual: return "Casual"
        case .neutral: return "Neutral"
        case .formal: return "Formal"
        }
    }

    public var description: String {
        switch self {
        case .casual:
            return "Friendly and relaxed"
        case .neutral:
            return "Balanced and natural"
        case .formal:
            return "Professional and polished"
        }
    }

    public var promptDescription: String {
        description
    }

    public var icon: String {
        switch self {
        case .casual: return "bubble.left.fill"
        case .neutral: return "bubble.middle.bottom.fill"
        case .formal: return "briefcase.fill"
        }
    }
}
