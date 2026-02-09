import Foundation

public enum InteractionMode: String, Codable, CaseIterable, Identifiable {
    case ptt
    case vad

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .ptt: return "Push-to-Talk"
        case .vad: return "Voice Activity Detection"
        }
    }

    public var description: String {
        switch self {
        case .ptt:
            return "Hold button to speak"
        case .vad:
            return "Automatic voice detection"
        }
    }

    public var icon: String {
        switch self {
        case .ptt: return "mic.circle.fill"
        case .vad: return "waveform.circle.fill"
        }
    }
}
