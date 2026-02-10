import Foundation
import AVFoundation
import SaphanCore

/// Manages the AVAudioSession configuration for voice translation
final class AudioSessionManager {

    // MARK: - Singleton

    static let shared = AudioSessionManager()

    private init() {}

    // MARK: - Properties

    private let logger = Logger.shared
    private let session = AVAudioSession.sharedInstance()

    // MARK: - Public Methods

    /// Configure audio session for voice translation
    /// Sets up play and record with voice chat mode
    func configureForVoiceTranslation() throws {
        logger.log("Configuring audio session for voice translation")

        do {
            // Configure category and mode
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )

            // Set preferred sample rate (24kHz for OpenAI Realtime API)
            try session.setPreferredSampleRate(Double(Constants.Voice.sampleRate))

            // Set preferred IO buffer duration (10ms for low latency)
            try session.setPreferredIOBufferDuration(0.01)

            // Activate the session
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            logger.log("Audio session configured successfully")
            logger.log("Sample rate: \(session.sampleRate) Hz")
            logger.log("IO buffer duration: \(session.ioBufferDuration) seconds")
            logger.log("Input channels: \(session.inputNumberOfChannels)")
            logger.log("Output channels: \(session.outputNumberOfChannels)")

        } catch {
            logger.error("Failed to configure audio session: \(error)")
            throw AudioSessionError.configurationFailed(error)
        }
    }

    /// Route audio to speaker (not earpiece)
    func routeToSpeaker() throws {
        logger.log("Routing audio to speaker")

        do {
            try session.overrideOutputAudioPort(.speaker)
            logger.log("Audio routed to speaker")
        } catch {
            logger.error("Failed to route audio to speaker: \(error)")
            throw AudioSessionError.routingFailed(error)
        }
    }

    /// Route audio to default output (earpiece or bluetooth)
    func routeToDefault() throws {
        logger.log("Routing audio to default output")

        do {
            try session.overrideOutputAudioPort(.none)
            logger.log("Audio routed to default output")
        } catch {
            logger.error("Failed to route audio to default: \(error)")
            throw AudioSessionError.routingFailed(error)
        }
    }

    /// Deactivate the audio session
    func deactivate() {
        logger.log("Deactivating audio session")

        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            logger.log("Audio session deactivated")
        } catch {
            logger.error("Failed to deactivate audio session: \(error)")
        }
    }

    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        logger.log("Requesting microphone permission")

        // Check current permission status
        let status = session.recordPermission

        switch status {
        case .granted:
            logger.log("Microphone permission already granted")
            return true

        case .denied:
            logger.log("Microphone permission denied")
            return false

        case .undetermined:
            logger.log("Requesting microphone permission from user")
            return await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    self.logger.log("Microphone permission \(granted ? "granted" : "denied")")
                    continuation.resume(returning: granted)
                }
            }

        @unknown default:
            logger.log("Unknown microphone permission status")
            return false
        }
    }

    /// Check if microphone permission is granted
    var isMicrophonePermissionGranted: Bool {
        session.recordPermission == .granted
    }

    /// Get current audio route information
    var currentRoute: AudioRoute {
        let currentRoute = session.currentRoute

        var inputs: [String] = []
        var outputs: [String] = []

        for input in currentRoute.inputs {
            inputs.append("\(input.portType.rawValue) - \(input.portName)")
        }

        for output in currentRoute.outputs {
            outputs.append("\(output.portType.rawValue) - \(output.portName)")
        }

        return AudioRoute(inputs: inputs, outputs: outputs)
    }

    /// Human-readable current output device for UI display.
    var currentOutputDeviceName: String {
        guard let output = session.currentRoute.outputs.first else {
            return "Unknown Output"
        }

        switch output.portType {
        case .builtInSpeaker:
            return "iPhone Speaker"
        case .builtInReceiver:
            return "Phone Earpiece"
        case .headphones:
            return "Wired Headphones"
        case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
            return output.portName
        case .airPlay:
            return "AirPlay"
        default:
            return output.portName
        }
    }

    /// Log current audio route
    func logCurrentRoute() {
        let route = currentRoute
        logger.log("Current audio route:")
        logger.log("  Inputs: \(route.inputs)")
        logger.log("  Outputs: \(route.outputs)")
    }

    /// Observe audio session interruptions
    func observeInterruptions(handler: @escaping (AudioSessionInterruption) -> Void) -> NotificationToken {
        let token = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }

            switch type {
            case .began:
                handler(.began)
                self.logger.log("Audio session interrupted")

            case .ended:
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    let shouldResume = options.contains(.shouldResume)
                    handler(.ended(shouldResume: shouldResume))
                    self.logger.log("Audio session interruption ended (should resume: \(shouldResume))")
                } else {
                    handler(.ended(shouldResume: false))
                    self.logger.log("Audio session interruption ended")
                }

            @unknown default:
                break
            }
        }

        return NotificationToken(token: token)
    }

    /// Observe audio route changes
    func observeRouteChanges(handler: @escaping (AudioRouteChangeReason) -> Void) -> NotificationToken {
        let token = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
            }

            self.logger.log("Audio route changed: \(reason.rawValue)")
            self.logCurrentRoute()

            let mappedReason = AudioRouteChangeReason(reason)
            handler(mappedReason)
        }

        return NotificationToken(token: token)
    }
}

// MARK: - Supporting Types

enum AudioSessionError: LocalizedError {
    case configurationFailed(Error)
    case routingFailed(Error)
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .configurationFailed(let error):
            return "Failed to configure audio session: \(error.localizedDescription)"
        case .routingFailed(let error):
            return "Failed to route audio: \(error.localizedDescription)"
        case .permissionDenied:
            return "Microphone permission denied"
        }
    }
}

struct AudioRoute {
    let inputs: [String]
    let outputs: [String]
}

enum AudioSessionInterruption {
    case began
    case ended(shouldResume: Bool)
}

enum AudioRouteChangeReason {
    case unknown
    case newDeviceAvailable
    case oldDeviceUnavailable
    case categoryChange
    case override
    case wakeFromSleep
    case noSuitableRouteForCategory
    case routeConfigurationChange

    init(_ avReason: AVAudioSession.RouteChangeReason) {
        switch avReason {
        case .unknown: self = .unknown
        case .newDeviceAvailable: self = .newDeviceAvailable
        case .oldDeviceUnavailable: self = .oldDeviceUnavailable
        case .categoryChange: self = .categoryChange
        case .override: self = .override
        case .wakeFromSleep: self = .wakeFromSleep
        case .noSuitableRouteForCategory: self = .noSuitableRouteForCategory
        case .routeConfigurationChange: self = .routeConfigurationChange
        @unknown default: self = .unknown
        }
    }
}

/// Token for managing notification observers
final class NotificationToken {
    private let token: NSObjectProtocol

    init(token: NSObjectProtocol) {
        self.token = token
    }

    deinit {
        NotificationCenter.default.removeObserver(token)
    }
}
