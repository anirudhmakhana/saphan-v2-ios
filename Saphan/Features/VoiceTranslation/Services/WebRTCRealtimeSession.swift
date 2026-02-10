import Foundation
import Combine
import AVFoundation
import SaphanCore

#if canImport(WebRTC)
import WebRTC
#else
#warning("WebRTC module not found. Run `xcodegen generate` and open `Saphan.xcworkspace`.")
#endif

/// WebRTC-based session for OpenAI Realtime API
@MainActor
final class WebRTCRealtimeSession: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var history: [ConversationItem] = []
    @Published private(set) var isSpeaking = false
    @Published private(set) var isTranslating = false
    @Published private(set) var isOutputSpeaking = false
    @Published private(set) var isCapturing = false

    // MARK: - Private Properties

    private var ephemeralToken: String?
    private var agent: RealtimeAgent
    private var selectedVoice: VoiceOption

    #if canImport(WebRTC)
    private var peerConnection: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?
    private var audioTrack: RTCAudioTrack?
    private var peerConnectionFactory: RTCPeerConnectionFactory?
    private var dataChannelOpenContinuation: CheckedContinuation<Void, Error>?
    #endif

    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let logger = Logger.shared

    // MARK: - Initialization

    init(agent: RealtimeAgent, voice: VoiceOption) {
        self.agent = agent
        self.selectedVoice = voice
        super.init()

        #if canImport(WebRTC)
        logger.log("WebRTC module available in this build")
        setupWebRTC()
        #else
        logger.error("WebRTC module unavailable in this build")
        #endif
    }

    // MARK: - Public Methods

    /// Connect to OpenAI Realtime API via WebRTC
    func connect(initialTurnDetection: TurnDetectionConfig = .defaultServerVAD) async throws {
        logger.log("Starting WebRTC Realtime connection")

        // Update state
        connectionState = .connecting

        // Step 1: Get ephemeral token from backend
        do {
            let tokenResponse = try await apiClient.getEphemeralToken(voice: selectedVoice.rawValue)
            ephemeralToken = tokenResponse.token
            logger.log("Obtained ephemeral token")
        } catch {
            logger.error("Failed to get ephemeral token: \(error)")
            connectionState = .error(error.localizedDescription)
            throw error
        }

        #if canImport(WebRTC)
        // Step 2: Setup WebRTC peer connection
        try await setupPeerConnection()

        // Step 3: Create and send SDP offer
        try await performSDPHandshake()

        // Step 4: Configure session
        try await configureRealtimeSession(initialTurnDetection: initialTurnDetection)

        // Connection successful
        connectionState = .connected
        logger.log("WebRTC Realtime connection established")
        #else
        // WebRTC not available - show error
        let error = NSError(
            domain: "WebRTCRealtimeSession",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "WebRTC framework not available in this build. Open `Saphan.xcworkspace`, run `pod install` after `xcodegen generate`, and use a physical iPhone for realtime voice testing."]
        )
        connectionState = .error(error.localizedDescription)
        throw error
        #endif
    }

    /// Disconnect from the session
    func disconnect() async {
        logger.log("Disconnecting WebRTC Realtime session")

        #if canImport(WebRTC)
        failDataChannelOpenIfNeeded(with: WebRTCError.dataChannelClosedBeforeOpen)
        dataChannel?.close()
        peerConnection?.close()
        dataChannel = nil
        peerConnection = nil
        audioTrack = nil
        #endif

        ephemeralToken = nil
        connectionState = .disconnected
        isSpeaking = false
        isTranslating = false
        isOutputSpeaking = false
        isCapturing = false

        logger.log("WebRTC session disconnected")
    }

    /// Mute the microphone
    func muteMicrophone() {
        #if canImport(WebRTC)
        audioTrack?.isEnabled = false
        isCapturing = false
        logger.log("Microphone muted")
        #endif
    }

    /// Unmute the microphone
    func unmuteMicrophone() {
        #if canImport(WebRTC)
        audioTrack?.isEnabled = true
        isCapturing = true
        logger.log("Microphone unmuted")
        #endif
    }

    /// Begin a PTT capture turn. Audio capture is active, but translation is not committed yet.
    func beginCaptureForPTT() {
        guard connectionState == .connected else { return }
        isTranslating = false
        isOutputSpeaking = false
        unmuteMicrophone()
    }

    /// End PTT capture and commit the turn for translation.
    func endCaptureAndCommitTurn() async throws {
        guard connectionState == .connected else { return }
        guard isCapturing else { return }

        muteMicrophone()
        try await sendClientEvent(type: "input_audio_buffer.commit")
        isTranslating = true
        try await sendClientEvent(type: "response.create")
    }

    /// Cancel the in-flight capture/translation/output turn immediately.
    func cancelCurrentTurn() async {
        guard connectionState == .connected else { return }
        muteMicrophone()
        isTranslating = false
        isOutputSpeaking = false

        do {
            try await sendClientEvent(type: "response.cancel")
            try await sendClientEvent(type: "input_audio_buffer.clear")
        } catch {
            logger.error("Failed to cancel current turn: \(error)")
        }
    }

    /// Stop assistant audio output immediately.
    func stopOutput() async {
        guard connectionState == .connected else { return }
        isOutputSpeaking = false
        isTranslating = false

        do {
            try await sendClientEvent(type: "response.cancel")
        } catch {
            logger.error("Failed to stop output: \(error)")
        }
    }

    /// Update session configuration
    func updateSessionConfig(turnDetection: TurnDetectionConfig) async throws {
        let message = RealtimeMessage.sessionUpdate(
            instructions: agent.instructions,
            voice: selectedVoice.rawValue,
            turnDetection: turnDetection
        )
        try await sendControlMessage(message)
    }

    /// Update the agent configuration
    func updateAgent(_ newAgent: RealtimeAgent, turnDetection: TurnDetectionConfig) {
        self.agent = newAgent

        // Send updated instructions if connected
        if case .connected = connectionState {
            Task {
                try? await updateSessionConfig(turnDetection: turnDetection)
            }
        }
    }

    /// Clear conversation history
    func clearHistory() {
        history.removeAll()
        logger.log("Conversation history cleared")
    }

    // MARK: - Private Methods - WebRTC Setup

    #if canImport(WebRTC)
    private func setupWebRTC() {
        // Initialize WebRTC factory
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory
        )
    }

    private func setupPeerConnection() async throws {
        guard let factory = peerConnectionFactory else {
            throw WebRTCError.factoryNotInitialized
        }

        // Configure ICE servers (STUN)
        let config = RTCConfiguration()
        config.iceServers = Constants.Voice.stunServers.map { url in
            RTCIceServer(urlStrings: [url])
        }
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually

        // Create peer connection
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
        )

        let pc = factory.peerConnection(with: config, constraints: constraints, delegate: self)
        peerConnection = pc

        let dataChannelConfig = RTCDataChannelConfiguration()
        dataChannelConfig.isOrdered = true
        guard let channel = pc.dataChannel(forLabel: "oai-events", configuration: dataChannelConfig) else {
            throw WebRTCError.dataChannelCreationFailed
        }
        dataChannel = channel
        dataChannel?.delegate = self
        logger.log("Data channel 'oai-events' created")

        // Add audio track
        let audioSource = factory.audioSource(with: nil)
        let audio = factory.audioTrack(with: audioSource, trackId: "audio0")
        peerConnection?.add(audio, streamIds: ["stream0"])
        audioTrack = audio

        logger.log("Peer connection created with audio track")
    }

    private func performSDPHandshake() async throws {
        guard let peerConnection = peerConnection,
              let token = ephemeralToken else {
            throw WebRTCError.notInitialized
        }

        // Create offer
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "false"
            ],
            optionalConstraints: nil
        )

        let offer = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<RTCSessionDescription, Error>) in
            peerConnection.offer(for: constraints) { sdp, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sdp = sdp {
                    continuation.resume(returning: sdp)
                } else {
                    continuation.resume(throwing: WebRTCError.sdpCreationFailed)
                }
            }
        }

        // Set local description
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            peerConnection.setLocalDescription(offer) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        logger.log("Local SDP offer created")

        // Send SDP offer to OpenAI
        let sdpString = offer.sdp
        let answer = try await sendSDPToOpenAI(sdp: sdpString, token: token)

        // Set remote description
        let remoteDescription = RTCSessionDescription(type: .answer, sdp: answer)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            peerConnection.setRemoteDescription(remoteDescription) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        logger.log("Remote SDP answer set")
    }

    private func sendSDPToOpenAI(sdp: String, token: String) async throws -> String {
        let url = URL(string: "\(Constants.Voice.openAIRealtimeURL)?model=\(Constants.Voice.realtimeModel)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.httpBody = sdp.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebRTCError.invalidSDPResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "No response body"
            logger.error("SDP handshake HTTP \(httpResponse.statusCode): \(errorMessage)")
            throw WebRTCError.sdpHandshakeFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        guard let answer = String(data: data, encoding: .utf8) else {
            throw WebRTCError.invalidSDPResponse
        }

        return answer
    }

    private func waitForDataChannelOpen(timeoutNanoseconds: UInt64 = 8_000_000_000) async throws {
        guard let dataChannel = dataChannel else {
            throw WebRTCError.dataChannelCreationFailed
        }

        if dataChannel.readyState == .open {
            return
        }

        logger.log("Waiting for data channel to open")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            if let existing = dataChannelOpenContinuation {
                dataChannelOpenContinuation = nil
                existing.resume(throwing: WebRTCError.dataChannelClosedBeforeOpen)
            }

            if let channel = self.dataChannel, channel.readyState == .open {
                continuation.resume()
                return
            }

            dataChannelOpenContinuation = continuation

            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                guard let self else { return }
                guard let pending = self.dataChannelOpenContinuation else { return }
                self.dataChannelOpenContinuation = nil
                pending.resume(throwing: WebRTCError.dataChannelOpenTimeout)
            }
        }
    }

    private func resolveDataChannelOpenIfNeeded() {
        guard let continuation = dataChannelOpenContinuation else { return }
        dataChannelOpenContinuation = nil
        continuation.resume()
    }

    private func failDataChannelOpenIfNeeded(with error: Error) {
        guard let continuation = dataChannelOpenContinuation else { return }
        dataChannelOpenContinuation = nil
        continuation.resume(throwing: error)
    }
    #endif

    // MARK: - Private Methods - Session Configuration

    private func configureRealtimeSession(initialTurnDetection: TurnDetectionConfig) async throws {
        #if canImport(WebRTC)
        // Wait for actual RTCDataChannel open event instead of a fixed sleep.
        try await waitForDataChannelOpen()
        #endif

        // Send session.update with instructions
        try await updateSessionConfig(turnDetection: initialTurnDetection)
    }

    // MARK: - Private Methods - Control Messages

    private func sendControlMessage(_ message: RealtimeMessage) async throws {
        #if canImport(WebRTC)
        guard let dataChannel = dataChannel, dataChannel.readyState == .open else {
            throw WebRTCError.dataChannelNotOpen
        }

        let encoder = JSONEncoder()
        let data = try encoder.encode(message)

        if message.type == "session.update",
           let payload = String(data: data, encoding: .utf8) {
            logger.log("Sending session.update payload: \(payload)")
        }

        let buffer = RTCDataBuffer(data: data, isBinary: false)
        dataChannel.sendData(buffer)

        logger.log("Sent control message: \(message.type)")
        #endif
    }

    private func sendClientEvent(type: String) async throws {
        #if canImport(WebRTC)
        try await sendClientEvent(payload: ["type": type])
        #endif
    }

    private func sendClientEvent(payload: [String: Any]) async throws {
        #if canImport(WebRTC)
        guard let dataChannel = dataChannel, dataChannel.readyState == .open else {
            throw WebRTCError.dataChannelNotOpen
        }

        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        let buffer = RTCDataBuffer(data: data, isBinary: false)
        dataChannel.sendData(buffer)
        logger.log("Sent client event: \(payload["type"] as? String ?? "unknown")")
        #endif
    }

    private func handleRealtimeMessage(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            let message = try decoder.decode(RealtimeEvent.self, from: data)

            logger.log("Received realtime event: \(message.type)")

            switch message.type {
            case "session.created":
                logger.log("Session created")

            case "conversation.item.created":
                if let item = message.item {
                    handleConversationItem(item)
                }

            case "response.audio.delta":
                isTranslating = false
                isOutputSpeaking = true

            case "response.audio_transcript.delta":
                if let delta = message.delta, let itemId = message.itemId {
                    updateTranscript(itemId: itemId, delta: delta)
                }

            case "response.audio_transcript.done":
                if let transcript = message.transcript, let itemId = message.itemId {
                    finalizeTranscript(itemId: itemId, transcript: transcript)
                }

            case "input_audio_buffer.speech_started":
                isSpeaking = true

            case "input_audio_buffer.speech_stopped":
                isSpeaking = false

            case "response.created":
                isTranslating = true

            case "response.done", "response.completed", "response.audio.done", "output_audio_buffer.stopped":
                isTranslating = false
                isOutputSpeaking = false

            case "error":
                if let error = message.error {
                    logger.error("Realtime API error: \(error.message ?? "Unknown error")")
                    isTranslating = false
                    isOutputSpeaking = false
                    isCapturing = false
                    connectionState = .error(error.message ?? "Unknown error")
                }

            default:
                logger.log("Unhandled event type: \(message.type)")
            }

        } catch {
            logger.error("Failed to decode realtime message: \(error)")
        }
    }

    private func handleConversationItem(_ item: ConversationItemData) {
        let conversationItem = ConversationItem(
            id: item.id,
            role: item.role,
            text: item.content?.first?.transcript ?? "",
            timestamp: Date()
        )

        if !history.contains(where: { $0.id == conversationItem.id }) {
            history.append(conversationItem)
        }
    }

    private func updateTranscript(itemId: String, delta: String) {
        if let index = history.firstIndex(where: { $0.id == itemId }) {
            history[index].text += delta
        } else {
            // Create new item with delta
            let item = ConversationItem(
                id: itemId,
                role: .assistant,
                text: delta,
                timestamp: Date()
            )
            history.append(item)
        }
    }

    private func finalizeTranscript(itemId: String, transcript: String) {
        if let index = history.firstIndex(where: { $0.id == itemId }) {
            history[index].text = transcript
        }
    }
}

// MARK: - RTCPeerConnectionDelegate

#if canImport(WebRTC)
extension WebRTCRealtimeSession: RTCPeerConnectionDelegate {

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        Task { @MainActor in
            logger.log("Signaling state changed: \(stateChanged.rawValue)")
        }
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        Task { @MainActor in
            logger.log("Media stream added")
        }
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        Task { @MainActor in
            logger.log("Media stream removed")
        }
    }

    nonisolated func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        Task { @MainActor in
            logger.log("Should negotiate")
        }
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        Task { @MainActor in
            logger.log("ICE connection state changed: \(newState.rawValue)")
        }
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        Task { @MainActor in
            logger.log("ICE gathering state changed: \(newState.rawValue)")
        }
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        Task { @MainActor in
            logger.log("ICE candidate generated")
        }
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        Task { @MainActor in
            logger.log("ICE candidates removed")
        }
    }

    nonisolated func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        Task { @MainActor in
            logger.log("Data channel opened: \(dataChannel.label)")
            self.dataChannel = dataChannel
            self.dataChannel?.delegate = self
            resolveDataChannelOpenIfNeeded()
        }
    }
}

// MARK: - RTCDataChannelDelegate

extension WebRTCRealtimeSession: RTCDataChannelDelegate {

    nonisolated func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        Task { @MainActor in
            logger.log("Data channel state changed: \(dataChannel.readyState.rawValue)")
            switch dataChannel.readyState {
            case .open:
                resolveDataChannelOpenIfNeeded()
            case .closing, .closed:
                failDataChannelOpenIfNeeded(with: WebRTCError.dataChannelClosedBeforeOpen)
            default:
                break
            }
        }
    }

    nonisolated func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        Task { @MainActor in
            handleRealtimeMessage(buffer.data)
        }
    }
}
#endif

// MARK: - Supporting Types

enum WebRTCError: LocalizedError {
    case factoryNotInitialized
    case peerConnectionCreationFailed
    case notInitialized
    case sdpCreationFailed
    case sdpHandshakeFailed(statusCode: Int?, message: String?)
    case invalidSDPResponse
    case dataChannelCreationFailed
    case dataChannelNotOpen
    case dataChannelOpenTimeout
    case dataChannelClosedBeforeOpen

    var errorDescription: String? {
        switch self {
        case .factoryNotInitialized:
            return "WebRTC factory not initialized"
        case .peerConnectionCreationFailed:
            return "Failed to create peer connection"
        case .notInitialized:
            return "Session not initialized"
        case .sdpCreationFailed:
            return "Failed to create SDP offer"
        case .sdpHandshakeFailed(let statusCode, let message):
            if let statusCode {
                if let message, !message.isEmpty {
                    return "SDP handshake failed (HTTP \(statusCode)): \(message)"
                }
                return "SDP handshake failed (HTTP \(statusCode))"
            }
            if let message, !message.isEmpty {
                return "SDP handshake failed: \(message)"
            }
            return "SDP handshake failed"
        case .invalidSDPResponse:
            return "Invalid SDP response from server"
        case .dataChannelCreationFailed:
            return "Failed to create data channel"
        case .dataChannelNotOpen:
            return "Data channel not open"
        case .dataChannelOpenTimeout:
            return "Timed out waiting for data channel to open"
        case .dataChannelClosedBeforeOpen:
            return "Data channel closed before opening"
        }
    }
}

struct TurnDetectionConfig: Codable {
    let type: String
    let threshold: Double?
    let prefixPaddingMs: Int?
    let silenceDurationMs: Int?

    enum CodingKeys: String, CodingKey {
        case type
        case threshold
        case prefixPaddingMs = "prefix_padding_ms"
        case silenceDurationMs = "silence_duration_ms"
    }

    static func serverVAD(threshold: Double, prefixPaddingMs: Int, silenceDurationMs: Int) -> TurnDetectionConfig {
        TurnDetectionConfig(
            type: "server_vad",
            threshold: threshold,
            prefixPaddingMs: prefixPaddingMs,
            silenceDurationMs: silenceDurationMs
        )
    }

    static var defaultServerVAD: TurnDetectionConfig {
        serverVAD(threshold: 0.5, prefixPaddingMs: 300, silenceDurationMs: 500)
    }

    static var disabled: TurnDetectionConfig {
        TurnDetectionConfig(type: "none", threshold: nil, prefixPaddingMs: nil, silenceDurationMs: nil)
    }
}

// MARK: - Realtime API Messages

struct RealtimeMessage: Codable {
    let type: String
    let session: SessionConfig?

    static func sessionUpdate(instructions: String, voice: String, turnDetection: TurnDetectionConfig) -> RealtimeMessage {
        let config = SessionConfig(
            type: "realtime",
            instructions: instructions,
            model: Constants.Voice.realtimeModel,
            audio: SessionAudioConfig(
                input: SessionAudioInputConfig(
                    transcription: TranscriptionConfig(model: "whisper-1"),
                    turnDetection: turnDetection
                ),
                output: SessionAudioOutputConfig(voice: voice)
            )
        )
        return RealtimeMessage(type: "session.update", session: config)
    }
}

struct SessionConfig: Codable {
    let type: String
    let instructions: String
    let model: String
    let audio: SessionAudioConfig

    enum CodingKeys: String, CodingKey {
        case type, instructions, model, audio
    }
}

struct SessionAudioConfig: Codable {
    let input: SessionAudioInputConfig
    let output: SessionAudioOutputConfig
}

struct SessionAudioInputConfig: Codable {
    let transcription: TranscriptionConfig
    let turnDetection: TurnDetectionConfig

    enum CodingKeys: String, CodingKey {
        case transcription
        case turnDetection = "turn_detection"
    }
}

struct SessionAudioOutputConfig: Codable {
    let voice: String
}

struct TranscriptionConfig: Codable {
    let model: String

    enum CodingKeys: String, CodingKey {
        case model
    }
}

// MARK: - Realtime API Events

struct RealtimeEvent: Codable {
    let type: String
    let item: ConversationItemData?
    let itemId: String?
    let delta: String?
    let transcript: String?
    let error: RealtimeError?

    enum CodingKeys: String, CodingKey {
        case type, item, delta, transcript, error
        case itemId = "item_id"
    }
}

struct ConversationItemData: Codable {
    let id: String
    let role: ConversationItem.Role
    let content: [ContentItem]?
}

struct ContentItem: Codable {
    let type: String
    let transcript: String?
}

struct RealtimeError: Codable {
    let type: String?
    let code: String?
    let message: String?
    let param: String?
}
