import Foundation

public enum VoiceOption: String, Codable, CaseIterable, Identifiable {
    case alloy
    case ballad
    case ash
    case shimmer

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .alloy: return "Alloy"
        case .ballad: return "Ballad"
        case .ash: return "Ash"
        case .shimmer: return "Shimmer"
        }
    }

    public var description: String {
        switch self {
        case .alloy:
            return "Neutral and balanced"
        case .ballad:
            return "Warm and expressive"
        case .ash:
            return "Clear and articulate"
        case .shimmer:
            return "Bright and energetic"
        }
    }

    public var icon: String {
        switch self {
        case .alloy: return "waveform.circle"
        case .ballad: return "music.note"
        case .ash: return "speaker.wave.2"
        case .shimmer: return "sparkles"
        }
    }
}
