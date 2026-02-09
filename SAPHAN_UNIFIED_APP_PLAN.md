# Saphan: Unified Swift App - Implementation Plan

## Overview

Combine three existing projects into a single native Swift app:
- All of these repos below are located here `/Users/anirudhmakhana/Documents/krsnalabs` and were built as a form of PoC
- **live-translator-mobile** (React Native) → Voice translation with OpenAI Realtime API
- **voice-translator-backend** (Node.js) → Keep as backend service
- **saphan-keyboard** (Swift) → iOS keyboard extension

## Current State Summary

### Live Translator Mobile (React Native)
- Real-time voice translation via OpenAI WebRTC Realtime API (`gpt-realtime`)
- 16 languages, 5 context modes (Dating, Social, Business, Travel, Emergency)
- PTT (Push-to-Talk) and VAD (Voice Activity Detection) modes
- 4 AI voices (alloy, ballad, ash, shimmer)
- Supabase auth, RevenueCat subscriptions
- Key file: `lib/openai/WebRTCRealtimeSession.ts` (WebRTC implementation)

### Voice Translator Backend (Node.js)
- REST API (no WebSocket - OpenAI handles real-time via WebRTC)
- `GET /token` - Ephemeral token for OpenAI Realtime API
- `POST /history/session` - Record session usage
- `GET /user/subscription` - Usage quota
- Auth via Supabase JWT, RevenueCat webhooks
- **Keep this backend** - Swift app will connect to it

### Saphan Keyboard (Swift)
- iOS keyboard extension with text translation
- Uses OpenAI Chat API (`gpt-4o-mini`)
- 12 languages, 5 tones (Casual, Professional, Friendly, Formal, Flirty)
- SwiftUI keyboard UI, App Group data sharing
- Key files: `SaphanShared/Services/` (reusable service patterns)

---

## Project Structure

```
Saphan/
├── Saphan.xcodeproj/
├── Saphan/                          # Main App Target
│   ├── App/
│   │   ├── SaphanApp.swift
│   │   └── AppDelegate.swift
│   ├── Features/
│   │   ├── VoiceTranslation/
│   │   │   ├── Views/
│   │   │   │   ├── VoiceTranslationView.swift
│   │   │   │   ├── LanguageSelectorView.swift
│   │   │   │   ├── ContextModePicker.swift
│   │   │   │   ├── ConversationBubbleView.swift
│   │   │   │   └── PTTButtonView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── VoiceTranslationViewModel.swift
│   │   │   └── Services/
│   │   │       ├── WebRTCRealtimeSession.swift
│   │   │       └── AudioSessionManager.swift
│   │   ├── Settings/
│   │   ├── Onboarding/
│   │   ├── Auth/
│   │   └── Subscription/
│   ├── Navigation/
│   │   ├── RootView.swift
│   │   └── MainTabView.swift
│   └── Resources/
│
├── SaphanKeyboard/                   # Keyboard Extension (migrate existing)
│   ├── KeyboardViewController.swift
│   ├── Views/
│   └── ViewModels/
│
├── SaphanCore/                       # Shared Framework
│   ├── Models/
│   │   ├── Language.swift
│   │   ├── Tone.swift
│   │   ├── ContextMode.swift
│   │   ├── Voice.swift
│   │   └── ConversationItem.swift
│   ├── Services/
│   │   ├── API/
│   │   │   └── APIClient.swift
│   │   ├── Auth/
│   │   │   ├── AuthService.swift
│   │   │   └── SupabaseClient.swift
│   │   ├── Translation/
│   │   │   └── TextTranslationService.swift
│   │   ├── Subscription/
│   │   │   └── SubscriptionService.swift
│   │   └── Storage/
│   │       ├── PreferencesService.swift
│   │       ├── KeychainService.swift
│   │       └── CacheService.swift
│   └── Utilities/
│
└── SaphanTests/
```

---

## Key Implementation Components

### 1. WebRTC Voice Translation (Port from React Native)

**Source:** `live-translator-mobile/lib/openai/WebRTCRealtimeSession.ts`

Port to Swift using GoogleWebRTC framework:

```swift
// WebRTCRealtimeSession.swift - Core connection logic
final class WebRTCRealtimeSession: NSObject {
    private var peerConnection: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?
    private var audioTrack: RTCAudioTrack?

    func connect() async throws {
        // 1. Get ephemeral token from backend (GET /token)
        // 2. Setup WebRTC peer connection with STUN servers
        // 3. Create audio track with echo cancellation
        // 4. Create data channel "oai-events" for control messages
        // 5. SDP handshake with OpenAI Realtime API
        // 6. Configure audio session for speaker output
    }

    func muteMicrophone() { audioTrack?.isEnabled = false }
    func unmuteMicrophone() { audioTrack?.isEnabled = true }
}
```

**Audio Configuration:**
- Sample rate: 24kHz (OpenAI preferred)
- Echo cancellation, noise suppression, auto gain control
- Route to speaker (not earpiece) via `AVAudioSession.overrideOutputAudioPort(.speaker)`

### 2. Shared Services (SaphanCore Framework)

**Migrate from:** `saphan-keyboard/SaphanShared/`

| Service | Purpose | App Group Shared |
|---------|---------|------------------|
| `APIClient` | Backend API calls | No |
| `AuthService` | Supabase authentication | Yes (token) |
| `SubscriptionService` | RevenueCat integration | Yes (status) |
| `PreferencesService` | User settings | Yes |
| `KeychainService` | Secure storage | Yes |
| `CacheService` | Translation cache | Yes |
| `TextTranslationService` | Keyboard text translation | Yes |

### 3. Context Modes (Voice Translation)

**Source:** `live-translator-mobile/app/(tabs)/index.tsx`

5 context modes with detailed prompts:
- **Dating** - Romantic, charming, warm
- **Social** - Casual, humorous, friendly
- **Business** - Formal, professional, authoritative
- **Travel** - Helpful, polite, clear
- **Emergency** - Direct, urgent, clear

Each mode includes system prompt with:
- Identity (translator, not conversational AI)
- Demeanor and tone specifications
- Formality level
- Native pronunciation requirements

### 4. Authentication Flow

**Source:** `live-translator-mobile/contexts/AuthContext.tsx`

```swift
// AuthService.swift
- signIn(email:password:) → Supabase auth
- signInWithApple() → Apple Sign-In → Supabase
- signInWithGoogle() → Google Sign-In → Supabase
- signOut()
- getAccessToken() → For API calls
```

### 5. Subscription Integration

**Source:** `live-translator-mobile/contexts/RevenueCatContext.tsx`

```swift
// SubscriptionService.swift
- identifyUser() → Link RevenueCat to Supabase user
- purchase(package:) → Handle IAP
- restorePurchases()
- refreshUsage() → GET /user/subscription
```

---

## Dependencies

| Dependency | Purpose | Integration |
|------------|---------|-------------|
| GoogleWebRTC | WebRTC framework | CocoaPods |
| supabase-swift | Auth & backend | SPM |
| purchases-ios | RevenueCat | SPM |
| GoogleSignIn-iOS | Google login | SPM |

**Podfile:**
```ruby
platform :ios, '16.0'

target 'Saphan' do
  use_frameworks!
  pod 'GoogleWebRTC', '~> 1.1'
end

target 'SaphanCore' do
  use_frameworks!
  pod 'GoogleWebRTC', '~> 1.1'
end
```

**Package.swift / Xcode SPM:**
```swift
.package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
.package(url: "https://github.com/RevenueCat/purchases-ios", from: "4.0.0"),
.package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
```

---

## App Group Configuration

**ID:** `group.com.krsnalabs.saphan`

Shared between main app and keyboard extension:
- `UserDefaults(suiteName:)` for preferences
- Keychain access group for API keys/tokens
- Shared container for cache files

**Entitlements (both targets):**
```xml
<key>com.apple.security.application-groups</key>
<array>
  <string>group.com.krsnalabs.saphan</string>
</array>
<key>keychain-access-groups</key>
<array>
  <string>$(AppIdentifierPrefix)com.krsnalabs.saphan</string>
</array>
```

---

## Critical Implementation Challenges

### 1. WebRTC in Swift
- Different API from React Native WebRTC
- Use `RTCPeerConnectionFactory` for audio source/track
- Handle delegates with Combine publishers for SwiftUI

**Key API Differences:**
```swift
// React Native: mediaDevices.getUserMedia()
// Swift: RTCPeerConnectionFactory.audioSource() + audioTrack()

// React Native: RTCSessionDescription(answer)
// Swift: RTCSessionDescription(type: .answer, sdp: sdp)

// React Native: peerConnection.ontrack
// Swift: RTCPeerConnectionDelegate.peerConnection(_:didAdd:)
```

### 2. Audio Routing
```swift
func configureAudioOutput() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(
        .playAndRecord,
        mode: .voiceChat,
        options: [.defaultToSpeaker, .allowBluetooth]
    )
    try session.overrideOutputAudioPort(.speaker)
    try session.setActive(true)
}
```

### 3. Keyboard Extension Limitations
- 30MB memory limit
- No network without Full Access
- Use static framework for SaphanCore
- Graceful degradation when Full Access disabled

---

## Implementation Phases

### Phase 1: Project Setup & SaphanCore
- [ ] Create new Xcode project with 3 targets (Saphan, SaphanKeyboard, SaphanCore)
- [ ] Configure App Group and entitlements
- [ ] Migrate models from saphan-keyboard
- [ ] Implement shared services (Keychain, Preferences, Cache, Network)
- [ ] Setup API client

### Phase 2: Authentication
- [ ] Integrate Supabase Swift SDK
- [ ] Implement email/password auth
- [ ] Add Apple Sign-In
- [ ] Add Google Sign-In
- [ ] Create auth UI flows (SignIn, SignUp views)

### Phase 3: Subscription
- [ ] Integrate RevenueCat SDK
- [ ] Implement SubscriptionService
- [ ] Create PaywallView
- [ ] Test purchase flow (sandbox)

### Phase 4: Keyboard Extension
- [ ] Migrate SaphanKeyboard code to new project
- [ ] Update to use SaphanCore framework
- [ ] Test App Group sharing
- [ ] Verify translation functionality

### Phase 5: Voice Translation (Core Feature)
- [ ] Integrate GoogleWebRTC (CocoaPods)
- [ ] Port WebRTCRealtimeSession to Swift
- [ ] Implement AudioSessionManager
- [ ] Build VoiceTranslationView (SwiftUI)
- [ ] Implement PTT/VAD modes
- [ ] Add conversation history UI
- [ ] Add context mode selection

### Phase 6: Polish & Testing
- [ ] Onboarding flow
- [ ] Settings screens
- [ ] Error handling refinement
- [ ] UI polish and animations
- [ ] Device testing
- [ ] App Store submission preparation

---

## Critical Files to Reference

| File | Purpose |
|------|---------|
| `live-translator-mobile/lib/openai/WebRTCRealtimeSession.ts` | WebRTC implementation to port to Swift |
| `live-translator-mobile/app/(tabs)/index.tsx` | Voice UI flow, state management, context modes |
| `saphan-keyboard/SaphanShared/Services/PreferencesService.swift` | App Group sharing pattern |
| `saphan-keyboard/SaphanShared/Services/TranslationService.swift` | API call patterns |
| `saphan-keyboard/SaphanKeyboard/KeyboardViewController.swift` | Keyboard extension entry point |
| `voice-translator-backend/src/services/openai.js` | Token generation logic |
| `voice-translator-backend/src/routes/token.js` | Token endpoint API |

---

## Data Models

### Language (16 for voice, 12 for keyboard)
```swift
struct Language: Codable, Identifiable {
    let code: String      // "en", "th", "es"
    let name: String      // "English", "Thai"
    let nativeName: String // "English", "ไทย"
    let flag: String      // "🇺🇸", "🇹🇭"
}
```

### Voice Options
```swift
enum VoiceOption: String, CaseIterable {
    case alloy    // Neutral & balanced
    case ballad   // Warm & expressive
    case ash      // Clear & articulate
    case shimmer  // Soft & gentle
}
```

### Context Modes
```swift
struct ContextMode: Identifiable {
    let id: String        // "dating", "social", "business"
    let name: String      // "Dating", "Social"
    let description: String
    let instructions: String  // Full system prompt
    let icon: String      // SF Symbol name
}
```

### Tones (Keyboard)
```swift
enum Tone: String, CaseIterable {
    case casual
    case professional
    case friendly
    case formal
    case flirty
}
```

---

## Verification Plan

1. **Unit Tests**
   - Services (APIClient, AuthService, SubscriptionService)
   - ViewModels
   - Models

2. **Integration Tests**
   - API client with mock server
   - Auth flow end-to-end

3. **Manual Testing**
   - Voice translation with real microphone input
   - PTT and VAD modes
   - Keyboard extension in messaging apps (iMessage, WhatsApp)
   - App Group data sync between app and keyboard
   - Subscription purchase flow (sandbox)
   - All 16 languages voice translation
   - All 5 context modes

4. **Device Testing**
   - Multiple iOS versions (16, 17, 18)
   - Different devices (iPhone, iPad)
   - Audio routing scenarios (speaker, AirPods, CarPlay)

---

## Notes

- Backend (voice-translator-backend) remains Node.js - no changes needed
- Keyboard extension memory limit requires careful optimization
- WebRTC is the most complex part - allocate extra time
- Test on real devices early (WebRTC doesn't work well in simulator)
