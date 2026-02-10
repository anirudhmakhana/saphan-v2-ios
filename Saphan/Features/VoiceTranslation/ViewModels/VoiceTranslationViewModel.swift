import Foundation
import Combine
import SwiftUI
import SaphanCore

enum MicTurnState: Equatable {
    case idle
    case recording
    case processing
    case speaking
}

enum AudioOutputPreference: String, CaseIterable, Identifiable {
    case automatic
    case speaker

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic:
            return "Auto"
        case .speaker:
            return "Speaker"
        }
    }
}

/// ViewModel for the voice translation feature
@MainActor
final class VoiceTranslationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var connectionState: ConnectionState = .disconnected
    @Published var language1: Language = .english
    @Published var language2: Language = .thai
    @Published var contextMode: ContextMode = .social
    @Published var interactionMode: InteractionMode = .vad
    @Published var selectedVoice: VoiceOption = .alloy
    @Published var isPTTActive = false
    @Published var isSpeaking = false
    @Published var isTranslating = false
    @Published var isOutputSpeaking = false
    @Published var micTurnState: MicTurnState = .idle
    @Published var audioOutputPreference: AudioOutputPreference = .automatic
    @Published var currentOutputDeviceName: String = "System Default"
    @Published var isWarmupInProgress = false
    @Published var isWarmupReady = false
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
    private var routeChangeToken: NotificationToken?
    private var cancellables = Set<AnyCancellable>()
    private var nextPTTTurnID: UInt64 = 0
    private var activePTTTurnID: UInt64?
    private var awaitingPTTResponse = false
    private var awaitingPTTOutput = false

    private let audioSessionManager = AudioSessionManager.shared
    private let keychainService = KeychainService()
    private let apiClient = APIClient.shared
    private let hapticManager = HapticManager.shared
    private let logger = Logger.shared

    // MARK: - Computed Properties

    var isConnected: Bool {
        connectionState == .connected
    }

    var isRecordingTurn: Bool {
        micTurnState == .recording
    }

    var isProcessingTurn: Bool {
        micTurnState == .processing
    }

    var isSpeakingTurn: Bool {
        micTurnState == .speaking
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
        observeAudioRouteChanges()
        refreshCurrentOutputDeviceName()
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
            micTurnState = .idle
            logger.error("Cannot start session: missing auth token")
            return
        }

        guard canConnect else {
            error = "Please select different languages"
            micTurnState = .idle
            return
        }

        logger.log("Starting voice translation session")

        // Request microphone permission
        let hasPermission = await audioSessionManager.requestMicrophonePermission()
        guard hasPermission else {
            error = "Microphone permission is required for voice translation"
            micTurnState = .idle
            logger.error("Microphone permission denied")
            return
        }

        // Configure audio session
        do {
            try audioSessionManager.configureForVoiceTranslation()
        } catch {
            self.error = "Failed to configure audio: \(error.localizedDescription)"
            micTurnState = .idle
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
            micTurnState = .idle
            return
        }

        // Create and connect session
        session = WebRTCRealtimeSession(agent: agent, voice: selectedVoice)
        bindToSession()

        do {
            try await session?.connect(initialTurnDetection: .defaultServerVAD)

            // Start session timer
            sessionStartTime = Date()
            startDurationTimer()

            // Always-on mode keeps capture active while connected.
            session?.unmuteMicrophone()
            applyAudioOutputPreference()

            hapticManager.success()
            micTurnState = .idle
            resetPTTTurnTracking()
            logger.log("Voice translation session started")

        } catch {
            self.error = "Failed to connect: \(error.localizedDescription)"
            logger.error("Connection failed: \(error)")
            session = nil
            micTurnState = .idle
            resetPTTTurnTracking()
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
        isTranslating = false
        isOutputSpeaking = false
        micTurnState = .idle
        resetPTTTurnTracking()

        audioSessionManager.deactivate()

        hapticManager.notification(type: .success)
        logger.log("Voice translation session ended")
    }

    /// Handle PTT button press
    func pttPressed() {
        guard isConnected, interactionMode == .ptt else { return }
        guard !isPTTActive else { return }

        logger.log("PTT pressed")
        nextPTTTurnID &+= 1
        activePTTTurnID = nextPTTTurnID
        awaitingPTTResponse = false
        awaitingPTTOutput = false
        isPTTActive = true
        micTurnState = .recording
        session?.beginCaptureForPTT()
        hapticManager.impact(style: .medium)
    }

    /// Handle PTT button release
    func pttReleased() {
        guard isConnected, interactionMode == .ptt else { return }
        guard isPTTActive else { return }
        guard micTurnState == .recording else { return }
        guard let turnID = activePTTTurnID else { return }

        logger.log("PTT released")
        isPTTActive = false
        micTurnState = .processing
        awaitingPTTResponse = true
        awaitingPTTOutput = true
        hapticManager.impact(style: .light)

        Task {
            do {
                try await session?.endCaptureAndCommitTurn()
            } catch {
                guard self.activePTTTurnID == turnID else { return }
                logger.error("Failed to commit PTT turn: \(error)")
                self.error = "Couldn't process that turn. Try again."
                self.micTurnState = .idle
                self.resetPTTTurnTracking()
            }
        }
    }

    func completeProcessingTurn() {
        guard micTurnState == .processing else { return }
        micTurnState = .speaking
        hapticManager.impact(style: .soft)
    }

    func completeSpeakingTurn() {
        micTurnState = .idle
        resetPTTTurnTracking()
        hapticManager.impact(style: .light)
    }

    func cancelPTTInteraction() {
        logger.log("PTT interaction cancelled")
        let shouldCancelRemoteTurn = isPTTActive || micTurnState == .processing || micTurnState == .speaking
        isPTTActive = false
        micTurnState = .idle
        resetPTTTurnTracking()

        guard shouldCancelRemoteTurn else { return }

        Task {
            await session?.cancelCurrentTurn()
        }
    }

    func stopTranslationOutput() async {
        isOutputSpeaking = false
        isTranslating = false
        if micTurnState != .recording {
            micTurnState = .idle
        }
        resetPTTTurnTracking()
        await session?.stopOutput()
    }

    /// Prefetch token/network path in the background to hide first-turn latency.
    func warmupRealtimeIfNeeded() {
        guard !isWarmupInProgress, !isWarmupReady else { return }
        guard keychainService.getAuthToken() != nil else { return }

        isWarmupInProgress = true

        Task {
            defer { isWarmupInProgress = false }

            do {
                _ = try await apiClient.getEphemeralToken(voice: selectedVoice.rawValue)
                isWarmupReady = true
            } catch {
                logger.error("Warmup failed: \(error)")
                isWarmupReady = false
            }
        }
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
                    try await session?.updateSessionConfig(turnDetection: .defaultServerVAD)
                    micTurnState = .idle
                    self.resetPTTTurnTracking()
                    session?.unmuteMicrophone()
                } else {
                    // Disable VAD for PTT mode
                    try await session?.updateSessionConfig(turnDetection: .disabled)
                    isPTTActive = false
                    micTurnState = .idle
                    self.resetPTTTurnTracking()
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

    func setAudioOutputPreference(_ preference: AudioOutputPreference) {
        guard audioOutputPreference != preference else { return }
        audioOutputPreference = preference
        applyAudioOutputPreference()
        hapticManager.selection()
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

    private func observeAudioRouteChanges() {
        routeChangeToken = audioSessionManager.observeRouteChanges { [weak self] _ in
            guard let self else { return }
            self.refreshCurrentOutputDeviceName()
        }
    }

    private func refreshCurrentOutputDeviceName() {
        currentOutputDeviceName = audioSessionManager.currentOutputDeviceName
    }

    private func applyAudioOutputPreference() {
        do {
            switch audioOutputPreference {
            case .automatic:
                try audioSessionManager.routeToDefault()
            case .speaker:
                try audioSessionManager.routeToSpeaker()
            }
            refreshCurrentOutputDeviceName()
        } catch {
            logger.error("Failed to apply audio output preference: \(error)")
        }
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

        session?.updateAgent(agent, turnDetection: .defaultServerVAD)
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

    private func resetPTTTurnTracking() {
        activePTTTurnID = nil
        awaitingPTTResponse = false
        awaitingPTTOutput = false
    }
}

// MARK: - Session Observation

extension VoiceTranslationViewModel {

    /// Bind to session publishers
    func bindToSession() {
        guard let session = session else { return }
        cancellables.removeAll()

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

        session.$isTranslating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isTranslating in
                guard let self else { return }
                self.isTranslating = isTranslating
                guard self.interactionMode == .ptt else { return }

                if isTranslating {
                    guard self.awaitingPTTResponse || self.awaitingPTTOutput || self.micTurnState == .processing else {
                        self.logger.log("Ignoring stale translating state in PTT mode")
                        return
                    }
                    if self.micTurnState != .recording {
                        self.micTurnState = .processing
                    }
                }
            }
            .store(in: &cancellables)

        session.$isOutputSpeaking
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isOutputSpeaking in
                guard let self else { return }
                self.isOutputSpeaking = isOutputSpeaking
                guard self.interactionMode == .ptt else { return }

                if isOutputSpeaking {
                    guard self.awaitingPTTOutput || self.micTurnState == .processing else {
                        self.logger.log("Ignoring stale speaking state in PTT mode")
                        return
                    }
                    self.awaitingPTTResponse = false
                    self.awaitingPTTOutput = false
                    self.completeProcessingTurn()
                } else if self.micTurnState == .speaking && !self.isPTTActive {
                    self.completeSpeakingTurn()
                }
            }
            .store(in: &cancellables)
    }
}
