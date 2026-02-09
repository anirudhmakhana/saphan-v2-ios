# Saphan Engineering Architecture

This document describes the production architecture and runtime behavior of the current native iOS implementation in this repository (`/saphan`) and its external backend dependency (`voice-translator-backend`), grounded in `SAPHAN_UNIFIED_APP_PLAN.md` and the implemented Swift code.

## 1. System Overview

Saphan is a multi-target iOS system with three runtime components:

1. `Saphan` (main iOS app, SwiftUI)
2. `SaphanKeyboard` (custom keyboard extension, UIKit host + SwiftUI UI)
3. `SaphanCore` (shared framework with models/services/utilities)

External services:

1. `voice-translator-backend` (Node.js REST backend, source of ephemeral tokens and usage APIs)
2. OpenAI Realtime API (`/v1/realtime/calls`) for live voice transport via WebRTC
3. OpenAI text translation API via backend `/translate` route for keyboard text translation

High-level data flow:

1. App authenticates user via backend (`/auth/login`, `/auth/signup`)
2. Auth token is stored in Keychain
3. Voice feature requests ephemeral realtime token via backend `GET /token`
4. iOS app establishes WebRTC peer connection to OpenAI Realtime
5. Session is configured with `session.update` over data channel (`oai-events`)
6. Realtime transcript events are mapped to UI conversation history
7. Session usage is intended to be recorded via backend `POST /history/session` (API exists; currently not called from voice VM)
8. Keyboard feature sends text translation requests to backend `/translate`

## 2. Codebase Topology and Ownership

## 2.1 Targets

Defined in `project.yml`:

1. `Saphan` (`application`)
2. `SaphanKeyboard` (`app-extension`)
3. `SaphanCore` (`framework`)
4. `SaphanTests` (`unit-test bundle`)

Important build behavior:

1. Xcode project generated via XcodeGen (`xcodegen generate`)
2. `postGenCommand: pod install` ensures CocoaPods are integrated after generation
3. Must open `Saphan.xcworkspace` (not `.xcodeproj`) for WebRTC builds

## 2.2 Primary runtime entrypoints

1. App: `Saphan/App/SaphanApp.swift`
2. App lifecycle hooks: `Saphan/App/AppDelegate.swift`
3. Root navigation state machine: `Saphan/Navigation/RootView.swift`
4. Keyboard entrypoint: `SaphanKeyboard/KeyboardViewController.swift`

## 3. Build/Dependency Architecture

## 3.1 Package dependencies (SPM)

Configured in `project.yml`:

1. `supabase-swift` (`from: 2.0.0`)
2. `purchases-ios` (`from: 4.0.0`)
3. `GoogleSignIn-iOS` (`from: 7.0.0`)

Note: These packages are present, but not all are fully wired into production flows yet (details in section 12).

## 3.2 CocoaPods dependency

`Podfile`:

1. `GoogleWebRTC ~> 1.1` for `Saphan`
2. `GoogleWebRTC ~> 1.1` for `SaphanCore`

Compile-time guard:

1. `WebRTCRealtimeSession.swift` uses `#if canImport(WebRTC)`
2. If not linked, runtime connection throws explicit error instructing workspace + pods usage

## 3.3 Environment and endpoint configuration

`SaphanCore/Constants.swift`:

1. Production backend default: `https://saphan-backend-production.up.railway.app`
2. Debug override: process env `SAPHAN_API_BASE_URL`
3. OpenAI realtime model: `gpt-realtime`
4. OpenAI SDP endpoint: `https://api.openai.com/v1/realtime/calls`

## 4. Runtime Architecture by Subsystem

## 4.1 App bootstrap and root routing

Flow implemented in `RootView`:

1. Splash screen (`1.5s` delay)
2. Onboarding gate (`PreferencesService.hasCompletedOnboarding`)
3. Authentication gate (`AuthViewModel.isAuthenticated`)
4. Main tabs (`VoiceTranslationView`, `SettingsView`)

This is a deterministic UI state machine:

1. `isLoading == true` -> Splash
2. `!hasCompletedOnboarding` -> Onboarding
3. `!isAuthenticated` -> Auth
4. else -> Main app

## 4.2 Authentication subsystem

Core files:

1. `Saphan/Features/Auth/ViewModels/AuthViewModel.swift`
2. `SaphanCore/Services/Auth/AuthService.swift`
3. `SaphanCore/Services/Storage/KeychainService.swift`

Auth backend contracts used:

1. `POST /auth/login`
2. `POST /auth/signup`

Response handling:

1. Expects `{ user, session }`
2. Reads `session.access_token` and optional `session.refresh_token`
3. Persists access token and serialized user in keychain

Session restoration:

1. On app init, `AuthViewModel.checkExistingSession()`
2. If token exists, sets `isAuthenticated = true`
3. Restores user payload from keychain if available

## 4.3 Voice translation subsystem (Realtime/WebRTC)

Core files:

1. `Saphan/Features/VoiceTranslation/ViewModels/VoiceTranslationViewModel.swift`
2. `Saphan/Features/VoiceTranslation/Services/AudioSessionManager.swift`
3. `Saphan/Features/VoiceTranslation/Services/WebRTCRealtimeSession.swift`
4. `Saphan/Features/VoiceTranslation/Services/RealtimeAgent.swift`

### 4.3.1 Pre-connection validation and setup

`VoiceTranslationViewModel.connect()` does:

1. Auth token presence check (`KeychainService`)
2. Language pair validity (`language1 != language2`)
3. Microphone permission check (`AVAudioSession.recordPermission`)
4. Audio session configuration:
   1. category `.playAndRecord`
   2. mode `.voiceChat`
   3. options `[.defaultToSpeaker, .allowBluetoothHFP]`
   4. preferred sample rate `24k`
   5. preferred IO buffer duration `10ms`

### 4.3.2 Realtime connection sequence

`WebRTCRealtimeSession.connect()`:

1. Set `connectionState = .connecting`
2. Request ephemeral token from backend `GET /token` (authorized with app bearer token)
3. Build `RTCPeerConnection` with STUN servers from `Constants.Voice.stunServers`
4. Create ordered `RTCDataChannel` labeled `oai-events`
5. Create local audio track and add to peer connection
6. Create SDP offer (`OfferToReceiveAudio=true`, `OfferToReceiveVideo=false`)
7. Set local SDP
8. POST SDP to OpenAI `/v1/realtime/calls?model=gpt-realtime` with `Authorization: Bearer <ephemeral token>`, content type `application/sdp`
9. Set remote SDP answer
10. Wait for data channel to become `.open` (continuation + timeout guard)
11. Send `session.update` configuration payload
12. Set `connectionState = .connected`

### 4.3.3 Realtime session config payload

Session config currently sent in `RealtimeMessage.sessionUpdate(...)`:

```json
{
  "type": "session.update",
  "session": {
    "type": "realtime",
    "instructions": "<generated by RealtimeAgent>",
    "model": "gpt-realtime",
    "audio": {
      "input": {
        "transcription": { "model": "whisper-1" },
        "turn_detection": {
          "type": "server_vad",
          "threshold": 0.5,
          "prefix_padding_ms": 300,
          "silence_duration_ms": 500
        }
      },
      "output": {
        "voice": "<alloy|ballad|ash|shimmer>"
      }
    }
  }
}
```

### 4.3.4 Event processing

Incoming `oai-events` messages decode to `RealtimeEvent` and are handled by type:

1. `session.created` -> log only
2. `conversation.item.created` -> append conversation item
3. `response.audio_transcript.delta` -> incremental transcript updates
4. `response.audio_transcript.done` -> finalize transcript
5. `input_audio_buffer.speech_started` -> `isSpeaking = true`
6. `input_audio_buffer.speech_stopped` -> `isSpeaking = false`
7. `error` -> `connectionState = .error(message)`

### 4.3.5 Interaction modes

`InteractionMode`:

1. `ptt`: mic muted by default, unmuted only while press/hold gesture active
2. `vad`: server turn detection enabled, mic stays unmuted

Mode transitions are applied by sending updated `session.update` payload with turn detection toggled between:

1. `server_vad(...)`
2. `none` (disabled)

### 4.3.6 Disconnect behavior

On disconnect:

1. close data channel and peer connection
2. clear session refs
3. deactivate audio session
4. reset UI state/timer/PTT state

Also, `VoiceTranslationView` auto-disconnects when app scene moves to background.

## 4.4 Keyboard extension subsystem

Core files:

1. `SaphanKeyboard/KeyboardViewController.swift`
2. `SaphanKeyboard/ViewModels/KeyboardViewModel.swift`
3. `SaphanKeyboard/Views/*.swift`

Architecture:

1. `UIInputViewController` hosts SwiftUI `KeyboardView` through `UIHostingController`
2. Keyboard uses `TranslationService` from `SaphanCore`
3. Input is tracked internally and mirrored to `UITextDocumentProxy`
4. Translation preview lifecycle:
   1. typing -> `state = .typing`
   2. request -> `state = .loading`
   3. success -> `state = .ready`, preview available
   4. failure -> `state = .error` or `.fullAccessRequired`

Network/security behavior:

1. Keyboard requires full access for network calls and pasteboard operations
2. `Info.plist` sets `RequestsOpenAccess = true`
3. View model blocks translation/paste with actionable error when full access is absent

## 5. Shared Data and Storage Boundaries

## 5.1 App Group

Configured in both targets via entitlements:

1. `com.apple.security.application-groups = group.com.krsnalabs.saphan`
2. shared `keychain-access-groups` with app prefix

## 5.2 Preferences storage

`PreferencesService` stores to `UserDefaults(suiteName: group.com.krsnalabs.saphan)`:

1. language defaults
2. tone/context/voice defaults
3. onboarding completion
4. interaction mode
5. feature toggles (haptics/sound/auto-translate)
6. subscription expiration (currently local flag)

## 5.3 Secret/session storage

`KeychainService` stores:

1. access token
2. refresh token
3. user id
4. serialized user profile

Accessibility class:

1. `kSecAttrAccessibleAfterFirstUnlock`

## 5.4 Cache

`CacheService`:

1. in-memory `NSCache`
2. persistent cache in app-group container `TranslationCache/`
3. cache key = SHA-256 hash over request tuple
4. TTL = 24 hours
5. used by keyboard text translation pipeline

## 6. API Contract Matrix

Client-side implemented backend endpoints:

1. `POST /auth/login`
2. `POST /auth/signup`
3. `GET /token`
4. `GET /user/subscription`
5. `POST /history/session`
6. `POST /translate`

Auth header semantics:

1. Backend APIs use `Authorization: Bearer <app_access_token>`
2. OpenAI realtime SDP call uses `Authorization: Bearer <ephemeral_token>`

Token response robustness:

`TokenResponse` decoder supports multiple backend shapes:

1. top-level `token`
2. top-level `value`
3. top-level `client_secret` or `clientSecret`
4. top-level `ephemeral_token` or `ephemeralToken`
5. nested `client_secret.value` or `client_secret.token`

This allows backend format migration without iOS release coupling.

## 7. UI and Theming Architecture

Voice screen UI:

1. `VoiceTranslationTheme` centralizes light/dark palettes
2. custom card surfaces, stroke system, CTA gradients
3. connection state drives CTA icon/text/gradient semantics
4. context and interaction mode controls are state-aware and disabled while connected where required

Dark mode:

1. Explicit palette split by `ColorScheme`
2. No simple inversion; distinct surfaces/strokes/text/accent values per mode

## 8. Concurrency and State Management

Concurrency model:

1. View models (`AuthViewModel`, `VoiceTranslationViewModel`, `SettingsViewModel`, `SubscriptionViewModel`, `KeyboardViewModel`) are `@MainActor`
2. network operations use Swift concurrency (`async/await`)
3. WebRTC delegate callbacks are `nonisolated`, bridged back to main actor with `Task { @MainActor ... }`
4. UI binds to reactive state via `@Published`
5. Voice VM subscribes to session publishers using Combine

Important guardrails:

1. realtime control messages only sent when data channel `readyState == .open`
2. data channel open uses continuation-based await with timeout; no fixed sleep dependency

## 9. Observability and Diagnostics

Logging:

1. centralized `Logger` wrapper over `os_log`
2. subsystem categories (`app`, `auth`, `network`, `voice`, etc.)
3. lifecycle and realtime events logged at each critical transition

Runtime diagnostics already surfaced in logs:

1. audio configuration (sample rate, IO buffer, channels)
2. WebRTC signaling/ICE transitions
3. session.update payload emission
4. realtime error events

## 10. Security and Privacy Model

## 10.1 Current strengths

1. OpenAI API key is not embedded in app; backend issues ephemeral realtime tokens
2. Long-lived app token stored in keychain, not UserDefaults
3. Keyboard network usage gated by explicit full access checks
4. App group used for controlled shared persistence

## 10.2 Sensitive paths

1. microphone capture during realtime sessions
2. keyboard extension has open access (required for network translation)
3. bearer tokens on backend and ephemeral token retrieval

## 10.3 Production hardening checklist

1. Pin backend TLS certificate/public key for mobile API calls
2. Add token refresh workflow and invalid token recovery in `AuthService`
3. Define strict backend response schemas and API versioning
4. Introduce privacy scrub mode to avoid logging user utterance content in production
5. Add abuse/rate telemetry around `/token` and `/translate`

## 11. Sequence Diagrams

## 11.1 Voice session startup

```text
User tap "Start"
  -> VoiceTranslationViewModel.connect()
    -> AudioSessionManager.requestMicrophonePermission()
    -> AudioSessionManager.configureForVoiceTranslation()
    -> WebRTCRealtimeSession.connect()
      -> APIClient.getEphemeralToken() [GET /token]
      -> RTCPeerConnection + data channel + audio track
      -> create local SDP offer
      -> POST SDP to OpenAI /v1/realtime/calls?model=gpt-realtime
      -> set remote SDP answer
      -> await data channel open
      -> send session.update over "oai-events"
    -> connectionState = connected
```

## 11.2 Keyboard translation

```text
User types/pastes
  -> KeyboardViewModel updates inputText/state
  -> requestTranslation()
    -> TranslationService.translate()
      -> optional cache hit
      -> POST /translate (with bearer token if present)
      -> decode TranslationResponse
      -> cache response
  -> preview shown
  -> user inserts translated text via UITextDocumentProxy
```

## 12. Planned vs Current (Important Gaps)

Aligned with plan:

1. Unified native architecture with shared core + keyboard extension
2. Backend-mediated ephemeral token flow
3. WebRTC realtime pipeline with context-aware instruction generation
4. App group-based shared preferences/cache strategy

Not fully production-complete yet:

1. Social auth placeholders:
   1. `signInWithApple()` and `signInWithGoogle()` are stubs with delayed placeholder messages
2. Subscription path:
   1. RevenueCat package exists, but `SubscriptionViewModel` is currently local/mock behavior
   2. No live purchase/restore integration yet
3. Usage/session accounting:
   1. `APIClient.recordSession(...)` exists but is not currently called at voice session teardown
4. Keychain sharing:
   1. `KeychainService` queries do not explicitly set `kSecAttrAccessGroup`
   2. cross-target sharing should be validated on physical device
5. Missing resilience features:
   1. no exponential retry/backoff strategy for transient realtime/network errors
   2. no circuit-breaker/feature flag fallback from realtime to text mode

## 13. Operational Runbook (Local and Device)

Build prerequisites:

1. `xcodegen generate`
2. `pod install` (or rely on post-gen hook)
3. open `Saphan.xcworkspace`
4. build/run on physical iPhone for realtime voice validation

Runtime environment override (debug):

1. set scheme env var `SAPHAN_API_BASE_URL` to point to local/staging backend
2. otherwise production Railway backend is used

Keyboard enablement:

1. install app to device
2. iOS Settings -> General -> Keyboard -> Keyboards -> Add New Keyboard -> Saphan
3. enable "Allow Full Access" for network translation and pasteboard support

## 14. Suggested Next Engineering Steps

1. Wire full OAuth and refresh-token lifecycle in auth module
2. Replace local subscription mock with real RevenueCat + backend entitlement sync
3. Persist and send voice session analytics/usage using `recordSession(...)`
4. Add explicit keychain access group attributes and test app/extension token sharing
5. Introduce integration tests for backend contract decoding (especially `/token` variants)
6. Add structured error taxonomy mapping OpenAI realtime errors to user-safe UX messages

