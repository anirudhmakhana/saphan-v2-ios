import Foundation
import Combine
import SwiftUI
import SaphanCore

/// ViewModel for the voice translation feature
@MainActor
final class VoiceTranslationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var connectionState: ConnectionState = .disconnected
    @Published var language1: Language = .english
    @Published var language2: Language = .thai
    @Published var contextMode: ContextMode = .social
    @Published var interactionMode: InteractionMode = .ptt
    @Published var selectedVoice: VoiceOption = .alloy
    @Published var isPTTActive = false
    @Published var isSpeaking = false
    @Published var history: [ConversationItem] = []
    @Published var sessionDuration: TimeInterval = 0
    @Published var showLanguagePicker = false
    @Published var showContextPicker = false
    @Published var showVoicePicker = false
    @Published var showLanguage1Picker = false
    @Published var showLanguage2Picker = false
    @Published var error: String?

    // MARK: - Private Properties

    private var session: WebRTCRealtimeSession?
    private var durationTimer: Timer?
    private var sessionStartTime: Date?
    private var cancellables = Set<AnyCancellable>()

    private let audioSessionManager = AudioSessionManager.shared
    private let keychainService = KeychainService()
    private let hapticManager = HapticManager.shared
    private let logger = Logger.shared

    // MARK: - Computed Properties

    var isConnected: Bool {
        connectionState == .connected
    }

    var canConnect: Bool {
        language1.code != language2.code
    }

    var connectionButtonTitle: String {
        switch connectionState {
        case .disconnected:
            return "Start Translation"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "End Translation"
        case .error:
            return "Retry"
        }
    }

    var sessionDurationFormatted: String {
        let minutes = Int(sessionDuration) / 60
        let seconds = Int(sessionDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Initialization

    init() {
        setupBindings()
    }

    deinit {
        durationTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Toggle connection state
    func toggleConnection() async {
        if isConnected {
            await disconnect()
        } else {
            await connect()
        }
    }

    /// Connect to the realtime translation service
    func connect() async {
        guard keychainService.getAuthToken() != nil else {
            error = "Please sign in before starting voice translation"
            logger.error("Cannot start session: missing auth token")
            return
        }

        guard canConnect else {
            error = "Please select different languages"
            return
        }

        logger.log("Starting voice translation session")

        // Request microphone permission
        let hasPermission = await audioSessionManager.requestMicrophonePermission()
        guard hasPermission else {
            error = "Microphone permission is required for voice translation"
            logger.error("Microphone permission denied")
            return
        }

        // Configure audio session
        do {
            try audioSessionManager.configureForVoiceTranslation()
        } catch {
            self.error = "Failed to configure audio: \(error.localizedDescription)"
            logger.error("Audio configuration failed: \(error)")
            return
        }

        // Create agent
        let agent = RealtimeAgent(
            language1: language1,
            language2: language2,
            contextMode: contextMode
        )

        guard agent.isValid else {
            error = agent.validationError
            return
        }

        // Create and connect session
        session = WebRTCRealtimeSession(agent: agent, voice: selectedVoice)
        bindToSession()

        do {
            try await session?.connect()

            // Start session timer
            sessionStartTime = Date()
            startDurationTimer()

            // Set initial microphone state based on interaction mode
            if interactionMode == .ptt {
                session?.muteMicrophone()
            }

            hapticManager.success()
            logger.log("Voice translation session started")

        } catch {
            self.error = "Failed to connect: \(error.localizedDescription)"
            logger.error("Connection failed: \(error)")
            session = nil
            audioSessionManager.deactivate()
        }
    }

    /// Disconnect from the session
    func disconnect() async {
        logger.log("Ending voice translation session")

        await session?.disconnect()
        session = nil

        stopDurationTimer()
        sessionDuration = 0
        sessionStartTime = nil
        isPTTActive = false

        audioSessionManager.deactivate()

        hapticManager.notification(type: .success)
        logger.log("Voice translation session ended")
    }

    /// Handle PTT button press
    func pttPressed() {
        guard isConnected, interactionMode == .ptt else { return }

        logger.log("PTT pressed")
        isPTTActive = true
        session?.unmuteMicrophone()
        hapticManager.impact(style: .medium)
    }

    /// Handle PTT button release
    func pttReleased() {
        guard isConnected, interactionMode == .ptt else { return }

        logger.log("PTT released")
        isPTTActive = false
        session?.muteMicrophone()
        hapticManager.impact(style: .light)
    }

    /// Toggle between PTT and VAD interaction modes
    func toggleInteractionMode() {
        guard isConnected else { return }

        logger.log("Applying interaction mode: \(interactionMode.rawValue)")
        let newMode = interactionMode
        let previousMode: InteractionMode = newMode == .ptt ? .vad : .ptt

        Task {
            do {
                if newMode == .vad {
                    // Enable server-side VAD
                    try await session?.updateSessionConfig(turnDetection: .serverVAD(
                        threshold: 0.5,
                        prefixPaddingMs: 300,
                        silenceDurationMs: 500
                    ))
                    session?.unmuteMicrophone()
                } else {
                    // Disable VAD for PTT mode
                    try await session?.updateSessionConfig(turnDetection: .disabled)
                    session?.muteMicrophone()
                }
                hapticManager.impact(style: .medium)
                logger.log("Interaction mode changed to \(newMode)")
            } catch {
                logger.error("Failed to update interaction mode: \(error)")
                // Revert on error
                interactionMode = previousMode
            }
        }
    }

    /// Swap language1 and language2
    func swapLanguages() {
        logger.log("Swapping languages")
        swap(&language1, &language2)
        hapticManager.impact(style: .light)

        // Update session if connected
        if isConnected {
            updateSessionAgent()
        }
    }

    /// Update language1
    func updateLanguage1(_ language: Language) {
        logger.log("Language1 changed to \(language.name)")
        language1 = language
        showLanguage1Picker = false
        hapticManager.selection()

        if isConnected {
            updateSessionAgent()
        }
    }

    /// Update language2
    func updateLanguage2(_ language: Language) {
        logger.log("Language2 changed to \(language.name)")
        language2 = language
        showLanguage2Picker = false
        hapticManager.selection()

        if isConnected {
            updateSessionAgent()
        }
    }

    /// Update context mode
    func updateContextMode(_ mode: ContextMode) {
        logger.log("Context mode changed to \(mode.name)")
        contextMode = mode
        hapticManager.selection()

        if isConnected {
            updateSessionAgent()
        }
    }

    /// Update voice option
    func updateVoice(_ voice: VoiceOption) {
        logger.log("Voice changed to \(voice.rawValue)")
        selectedVoice = voice
        showVoicePicker = false
        hapticManager.selection()

        // Note: Voice change requires reconnection
        // TODO: Show alert asking if user wants to reconnect
    }

    /// Clear conversation history
    func clearHistory() {
        logger.log("Clearing conversation history")
        history.removeAll()
        session?.clearHistory()
        hapticManager.impact(style: .light)
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Observe session state changes
        // Note: Bindings will be set up when session is created
    }

    private func updateSessionAgent() {
        let agent = RealtimeAgent(
            language1: language1,
            language2: language2,
            contextMode: contextMode
        )

        guard agent.isValid else {
            error = agent.validationError
            return
        }

        session?.updateAgent(agent)
    }

    private func startDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.sessionStartTime else { return }
                self.sessionDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
}

// MARK: - Session Observation

extension VoiceTranslationViewModel {

    /// Bind to session publishers
    func bindToSession() {
        guard let session = session else { return }

        // Observe connection state
        session.$connectionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionState)

        // Observe conversation history
        session.$history
            .receive(on: DispatchQueue.main)
            .assign(to: &$history)

        // Observe speaking state
        session.$isSpeaking
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSpeaking)
    }
}
