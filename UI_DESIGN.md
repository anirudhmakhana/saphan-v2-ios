# Saphan — UI Design Specification
### Version 1.0 — Full App Revamp

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [Color System](#2-color-system)
3. [Typography System](#3-typography-system)
4. [Component Library](#4-component-library)
5. [Screen Specifications](#5-screen-specifications)
   - 5.1 [Auth Screen](#51-auth-screen)
   - 5.2 [Voice Translation Screen](#52-voice-translation-screen)
   - 5.3 [Settings Screen](#53-settings-screen)
   - 5.4 [Paywall Screen](#54-paywall-screen)
   - 5.5 [Onboarding](#55-onboarding)
6. [Motion & Animation](#6-motion--animation)
7. [Interaction Patterns](#7-interaction-patterns)

---

## 1. Design Philosophy

Saphan is not a utility app with a voice feature. It is a bridge — between people who cannot yet speak to each other. Every design decision must earn its place by reducing friction, building warmth, or reinforcing that this moment of connection matters.

The visual language takes direct inspiration from two directions simultaneously: the atmospheric, full-bleed editorial gravity of premium finance apps (pure black grounds, enormous typographic authority, everything breathing in generous space) and the soft organic presence of voice-first AI interfaces (morphing blobs, gentle gradients, living ambient light). The result is a dark atmospheric canvas punctuated by a living voice orb — minimal enough to disappear when not needed, expressive enough to communicate what the AI is doing without a single word of UI copy.

Saphan's UI earns trust through restraint. Nothing competes with the act of speaking. The interface recedes when the user talks and re-emerges to present the translation. Color is used sparingly: the brand coral (#E07856) appears only at moments of action or completion, never as decoration. Everything else — backgrounds, surfaces, labels — is achromatic or near-neutral.

The app targets a specific emotional register: the feeling of stepping off a plane, hearing a language you do not know, and realizing that you are going to be okay. Calm confidence. A quiet bridge held open.

The design system is intentionally bimodal. The Voice Translation screen (the heart of the product) uses a pure dark atmospheric treatment regardless of system appearance. All other screens (Settings, Language Picker, Conversation History) follow the system color scheme using the existing `SaphanTheme.Palette` infrastructure.

---

## 2. Color System

### 2.1 Brand Palette

The existing brand coral is retained and refined. Supporting colors are shifted to support the new dark-atmospheric direction.

```
Brand Coral (Primary Accent)      #E07856   Color(red: 224/255, green: 120/255, blue: 86/255)
Brand Coral Dim (Pressed/Hover)   #D06A4A   Color(red: 208/255, green: 106/255, blue: 74/255)
Brand Warm Sand (Secondary)       #C1A28B   Color(red: 193/255, green: 162/255, blue: 139/255)
```

### 2.2 Atmospheric Dark Canvas (Voice Translation Screen + Auth + Paywall + Onboarding)

These screens share a full-bleed dark treatment that is not simply black — it has directional warmth drawn from the Bangkok sunset palette.

```
Canvas Deep         #0E0F10   Color(red: 14/255,  green: 15/255,  blue: 16/255)
Canvas Mid          #141618   Color(red: 20/255,  green: 22/255,  blue: 24/255)
Canvas Warm         #1C1A18   Color(red: 28/255,  green: 26/255,  blue: 24/255)
Surface Elevated    #242220   Color(red: 36/255,  green: 34/255,  blue: 32/255)
Surface Glass       Color.white.opacity(0.06)  — frosted panel backgrounds
Stroke Subtle       Color.white.opacity(0.08)  — card and pill borders
Stroke Active       Color.white.opacity(0.18)  — focused states
```

The atmospheric background gradient for full-screen dark views:

```swift
// SwiftUI implementation
LinearGradient(
    stops: [
        .init(color: Color(red: 14/255, green: 15/255, blue: 16/255), location: 0.0),
        .init(color: Color(red: 20/255, green: 19/255, blue: 22/255), location: 0.45),
        .init(color: Color(red: 24/255, green: 20/255, blue: 18/255), location: 1.0)
    ],
    startPoint: .top,
    endPoint: .bottom
)
```

The visual effect is a barely perceptible warmth at the bottom — like candlelight seen through stone — that prevents the dark screen from feeling dead or corporate.

### 2.3 Light Mode System Palette (Settings + Sheets)

```
Background Primary    #FAFAF8   Color(red: 250/255, green: 250/255, blue: 248/255)
Background Secondary  #F2F0EC   Color(red: 242/255, green: 240/255, blue: 236/255)
Surface               #FFFFFF
Surface Elevated      #FFFFFF
Stroke                #E0DDD8   Color(red: 224/255, green: 221/255, blue: 216/255)
Primary Text          #1A1A1C   Color(red: 26/255,  green: 26/255,  blue: 28/255)
Secondary Text        #6B7177   Color(red: 107/255, green: 113/255, blue: 119/255)
```

### 2.4 Semantic Colors (Both Modes)

```
Success Green     #34C759   Color(red: 52/255,  green: 199/255, blue: 89/255)
Warning Amber     #DDA447   Color(red: 221/255, green: 164/255, blue: 71/255)
Danger Red        #FF6060   Color(red: 255/255, green: 96/255,  blue: 96/255)
```

### 2.5 Voice Orb Color System

The orb is the emotional center of the app. Its color layers shift based on state. These values are used as gradient stops and blur overlays.

```
Orb Outer Glow (Idle)        #4ECDC4   opacity 0.25  — soft teal haze
Orb Outer Glow (Listening)   #E07856   opacity 0.30  — coral warm pulse
Orb Outer Glow (Translating) #DDA447   opacity 0.30  — amber shimmer
Orb Outer Glow (Speaking)    #34C759   opacity 0.25  — green settle

Orb Inner Core (Idle)        #2A3540 → #1C2A34  — dark teal-slate gradient
Orb Inner Core (Listening)   #3D2318 → #5C3020  — deep coral-ember gradient
Orb Inner Core (Translating) #3D2E10 → #4A3818  — deep amber gradient
Orb Inner Core (Speaking)    #143020 → #1A3828  — deep green gradient
```

---

## 3. Typography System

### 3.1 Primary Font

**SF Pro Rounded** is the primary typeface across all screens. It is available natively on iOS without bundling, aligns with Saphan's warm-yet-precise personality, and renders the rounded personality of the brand without importing external fonts.

For headings and display text, SF Pro Display (or SF Pro Rounded at larger sizes) is used.

```swift
// SwiftUI font references
.font(.system(size: 13, weight: .semibold, design: .rounded))
.font(.system(size: 15, weight: .medium, design: .rounded))
.font(.system(size: 17, weight: .semibold, design: .rounded))
.font(.system(size: 22, weight: .bold, design: .rounded))
.font(.system(size: 32, weight: .bold, design: .rounded))
.font(.system(size: 44, weight: .bold))  // Display — use default (SF Pro Display)
```

### 3.2 Type Scale

| Role | Size | Weight | Design | Line Height | Tracking |
|------|------|--------|--------|-------------|---------|
| Display Hero | 44pt | Bold | Default (Display) | 1.1 | -0.5pt |
| Heading 1 | 32pt | Bold | Rounded | 1.2 | -0.3pt |
| Heading 2 | 24pt | Semibold | Rounded | 1.25 | -0.2pt |
| Heading 3 | 20pt | Semibold | Rounded | 1.3 | 0 |
| Body Large | 17pt | Medium | Rounded | 1.5 | 0 |
| Body | 15pt | Regular | Rounded | 1.55 | 0 |
| Label | 13pt | Semibold | Rounded | 1.4 | 0 |
| Caption | 11pt | Semibold | Rounded | 1.3 | +0.3pt |
| Micro Label | 10pt | Bold | Rounded | 1.0 | +0.8pt |

### 3.3 Typography Rules

**On dark atmospheric backgrounds (Voice, Auth, Onboarding, Paywall):**
- Primary content: `.white`
- Secondary / supporting: `.white.opacity(0.6)`
- Small-caps labels (e.g., "YOU SAID", "THAI"): `.white.opacity(0.4)`, 11pt Bold, +0.8pt tracking — these are editorial, not informational

**On system backgrounds (Settings, Sheets):**
- Use system `.primary` and `.secondary` for automatic adaptation
- Accent labels: `#E07856` (`SaphanTheme.brandCoral`)

**Transcript text (most important content on the screen):**
- Source language: 22pt Semibold Rounded, white
- Translation output: 22pt Semibold Rounded, `#E07856` (coral) — the translated text gets the brand color because it is the output that matters

---

## 4. Component Library

### 4.1 Voice Orb / Blob

The orb is a custom SwiftUI view that uses `Canvas` for blob rendering, layered with `ZStack`, gaussian blur, and state-driven animation.

**Visual structure (bottom to top):**

```
Layer 1 — Ambient Glow Ring
  Circle, 240pt diameter
  Fill: radial gradient, orb outer glow color → clear
  Blur: .blur(radius: 48)
  Opacity: 0.6, animated on state change

Layer 2 — Soft Aura Ring
  Circle, 190pt diameter
  Fill: orb inner core gradient, opacity 0.25
  Blur: .blur(radius: 24)

Layer 3 — Main Orb Body
  Custom blob path (see §4.1.1), 148pt bounding square
  Fill: RadialGradient, inner core colors
  Blend mode: .normal
  Blur: .blur(radius: 2)  — very slight to soften edges

Layer 4 — Specular Highlight
  Ellipse, 40pt × 24pt
  Fill: white, opacity 0.12
  Offset: (-20pt, -30pt) from orb center
  Blur: .blur(radius: 6)

Layer 5 — Waveform / Icon Overlay
  System icon, 28pt, weight .medium
  Foreground: .white.opacity(0.85)
  Centered in orb
```

**4.1.1 Blob Path Generation**

The blob is not a perfect circle. It is approximated using a `Path` with 6 bezier control points that morph over time using `withAnimation` and `TimelineView`. The morphing is achieved by randomizing control point offsets within a bounded range on each animation cycle.

```swift
// Conceptual SwiftUI blob path approach
struct BlobShape: Shape {
    var phase: CGFloat  // 0.0 → 1.0, animatable

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let r: CGFloat = min(rect.width, rect.height) / 2 * 0.88

        // 6 perimeter points with phase-driven offsets
        // Each point radius is r + sin(angle + phase * 2π) * amplitude
        let amplitude: CGFloat = r * 0.12
        let points = (0..<6).map { i -> CGPoint in
            let angle = CGFloat(i) / 6 * .pi * 2
            let phaseShift = phase * .pi * 2 + CGFloat(i) * .pi / 3
            let radius = r + sin(phaseShift) * amplitude
            return CGPoint(
                x: cx + cos(angle) * radius,
                y: cy + sin(angle) * radius
            )
        }

        // Smooth through points with cubic bezier curves
        var path = Path()
        // ... cubic bezier interpolation between points
        return path
    }
}
```

In practice, pair `BlobShape` with a `TimelineView(.animation)` that drives `phase` forward by a small increment each frame, creating a continuous slow morph.

**4.1.2 Orb States and Transitions**

```
IDLE
  Orb diameter: 148pt
  Animation: slow breathing — scale 1.0 → 1.04 → 1.0, duration 3.2s, easeInOut, repeat
  Glow: teal (#4ECDC4), opacity 0.20
  Blob morph: very slow (phase increment: 0.002 per frame)
  Icon: mic symbol, opacity 0.7

CONNECTING
  Diameter: 148pt
  Animation: gentle pulse, scale 1.0 → 1.06 → 1.0, duration 1.4s, easeInOut, repeat
  Glow: amber (#DDA447), opacity 0.25
  Blob morph: slow (0.003 per frame)
  Icon: hourglass symbol, opacity 0.6

LISTENING (mic open, speech detected)
  Diameter: 148pt → 160pt (spring animation on speech start)
  Animation: reactive — scale driven by audio amplitude, range 1.0 → 1.14
  Glow: coral (#E07856), opacity 0.35, also reacts to amplitude
  Blob morph: fast (0.008 per frame)
  Icon: waveform symbol, opacity 0.9

TRANSLATING
  Diameter: 152pt (slight expand from idle)
  Animation: slow orbit shimmer — a semi-transparent arc rotates around the orb
  Glow: amber, opacity 0.30
  Blob morph: medium (0.004 per frame)
  Icon: no icon — remove with .opacity(0) crossfade

SPEAKING OUTPUT
  Diameter: 148pt → 156pt (spring on output start)
  Animation: steady pulse sync'd to output speech rhythm (approximate)
  Glow: green (#34C759), opacity 0.28
  Blob morph: medium (0.005 per frame)
  Icon: speaker.wave.2 symbol, opacity 0.85
```

**4.1.3 SwiftUI Implementation Hints**

```swift
// State-to-glow color helper
private func orbGlowColor(for state: ConnectionState, isSpeaking: Bool, isOutputSpeaking: Bool) -> Color {
    if isOutputSpeaking { return Color(red: 52/255, green: 199/255, blue: 89/255) }
    if isSpeaking { return Color(red: 224/255, green: 120/255, blue: 86/255) }
    switch state {
    case .connecting:   return Color(red: 221/255, green: 164/255, blue: 71/255)
    case .connected:    return Color(red: 224/255, green: 120/255, blue: 86/255)
    default:            return Color(red: 78/255,  green: 205/255, blue: 196/255)
    }
}

// Breathing animation
@State private var breathScale: CGFloat = 1.0

private func startBreathing() {
    withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
        breathScale = 1.04
    }
}
```

Use `.matchedGeometryEffect` to smoothly transition the orb between its resting and active positions if the layout shifts when the keyboard appears.

---

### 4.2 Action Bar (Bottom Controls)

The action bar sits at the bottom of the Voice Translation screen, floating above the safe area inset. It is not a tab bar — it is contextual and changes its contents based on translation state.

**Visual specification:**

```
Container
  Background: ultraThinMaterial (blur) on dark background, or:
              Color(white: 0.08) + .clipShape(Capsule()) for a pill-shaped bar
  Padding: 16pt horizontal, 12pt vertical
  Corner radius: 48pt (full pill)
  Width: dynamic, centered, not full-width
  Max width: UIScreen.main.bounds.width - 48pt
  Shadow: color .black.opacity(0.40), radius 24, y 8
  Border: Color.white.opacity(0.10), lineWidth 1

Layout: HStack with fixed-size side buttons and a centered hero button
  Left button:  44pt × 44pt circle
  Center button: 72pt × 72pt circle  (the primary mic/stop button)
  Right button:  44pt × 44pt circle
  Spacing: 20pt between each button
```

**Idle state (not connected):**
```
Left:   globe.europe.africa.fill icon — opens language picker
Center: Mic button (72pt circle, filled coral #E07856 gradient, white mic icon 24pt)
Right:  slider.horizontal.3 icon — opens Advanced Controls sheet
```

**Active / Listening state:**
```
Left:   clock.arrow.circlepath — opens Conversation History
Center: Stop button (72pt circle, filled #242220, white stop.fill icon 22pt)
          Ring around stop button: 2pt coral stroke, animated dash offset rotation
Right:  speaker.wave.2.fill — toggles audio output route
```

**Output Speaking state:**
```
Left:   clock.arrow.circlepath — history
Center: Stop Output button (72pt circle, filled with ambient green gradient)
          Icon: speaker.slash.fill 22pt white
Right:  slider.horizontal.3 — Advanced Controls
```

**Hero button micro-interaction:**
- Scale to 0.92 on press, spring back on release
- On press: add a short radial ring ripple outward, color matching current state color, opacity 0.4 → 0

**Side button visual:**
```swift
// Side button template
Circle()
    .fill(Color.white.opacity(0.08))
    .frame(width: 44, height: 44)
    .overlay(
        Image(systemName: iconName)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.white.opacity(0.75))
    )
    .overlay(
        Circle()
            .stroke(Color.white.opacity(0.10), lineWidth: 1)
    )
```

---

### 4.3 Frosted Glass Pill Tags

Small capsule labels used throughout the interface for language labels, state indicators, and contextual hints.

**Spec:**

```
Background:   .ultraThinMaterial  — on dark screens
              Color.white.opacity(0.08) with .blur(radius: 12) if using custom approach
Border:       Color.white.opacity(0.12), lineWidth: 1
Corner:       Capsule() — fully rounded
Padding:      horizontal 12pt, vertical 6pt
Typography:   11pt Bold Rounded, Color.white.opacity(0.80), tracking +0.5pt
```

**SwiftUI implementation:**

```swift
struct GlassPill: View {
    let text: String
    var iconName: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let icon = iconName {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.70))
            }
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.80))
                .tracking(0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}
```

**Usage locations:**
- Below orb: shows current context mode, e.g. "Social" or "Dating"
- Top bar: language pair indicator — "EN  →  TH"
- Status pill: connection state in top-left corner

---

### 4.4 Language Switcher

A horizontal component that sits above the orb, showing the two active languages with a swap arrow in the center. This replaces the current "Target: Thai" pill in the top bar.

**Spec:**

```
Container
  Width: 280pt fixed (or .infinity with max 300pt)
  Height: 48pt
  Background: Color.white.opacity(0.06)
  Border: Color.white.opacity(0.10), lineWidth: 1
  Corner radius: 24pt (Capsule)
  Layout: HStack

Language Pill (left and right, equal width)
  Text: language name, 14pt Semibold Rounded, white
  Flag emoji: 18pt, leading
  Subtext: language code (e.g. "EN"), 11pt Regular, white.opacity(0.50)
  Tappable: full area, opens language picker on tap
  Pressed state: background tint to Color.white.opacity(0.10)

Center Swap Button
  Width: 44pt, height: 44pt
  Icon: arrow.left.arrow.right, 15pt, weight .semibold
  Color: white.opacity(0.60)
  Pressed state: icon rotates 180° with .spring, then snaps back
  Action: swaps source and target language, with cross-dissolve text transition
```

**Swap animation:**

```swift
@State private var swapRotation: Double = 0

// On swap tap:
withAnimation(.spring(response: 0.30, dampingFraction: 0.70)) {
    swapRotation += 180
}
// Update language pair simultaneously
```

---

### 4.5 Transcript Display Block

Shows the latest exchange: what was said and the translation. This floats above the action bar in the lower portion of the screen, over the orb's ambient glow region.

**Spec:**

```
Container
  Position: above action bar, below orb — approximately 48pt from bottom of orb
  Background: none (transparent — content reads over the ambient orb glow)
  Padding: horizontal 28pt

"YOU SAID" label
  11pt Bold Rounded, Color.white.opacity(0.35), tracking +0.8pt
  Uppercase

Source transcript text
  22pt Semibold Rounded
  Color: white.opacity(0.90)
  Line height: 1.3
  Max lines: 3, then truncates with ellipsis
  Transition: .transition(.opacity.combined(with: .move(edge: .bottom)))

Language name label (for translation)
  11pt Bold Rounded, Color #E07856 (coral), tracking +0.8pt
  Uppercase

Translated text
  22pt Semibold Rounded
  Color: #E07856 (coral)
  Line height: 1.3
  Max lines: 4
  This text gets the brand accent — it is the output that deserves attention
  Transition: .transition(.opacity.combined(with: .move(edge: .bottom)))
```

**Empty state (no transcript yet):**

Centered in the upper portion of the screen (between language switcher and orb center), display a single hint line:

```
"Speak. I'll translate."
17pt Medium Rounded, Color.white.opacity(0.35)
Centered horizontally
```

No icon. No explanation. The orb communicates everything else.

---

### 4.6 Session Timer

```
Monospaced, 13pt, weight .semibold, design .monospaced
Color: Color.white.opacity(0.35)
Position: centered below action bar, above safe area bottom
Format: MM:SS
```

---

## 5. Screen Specifications

### 5.1 Auth Screen

**Background:**
Full-bleed atmospheric gradient — identical to the Voice Translation screen. The auth screen is the first impression, and it must immediately communicate the visual world the user is entering.

```swift
// Background gradient
LinearGradient(
    stops: [
        .init(color: Color(red: 14/255, green: 15/255, blue: 16/255), location: 0.0),
        .init(color: Color(red: 20/255, green: 19/255, blue: 22/255), location: 0.45),
        .init(color: Color(red: 24/255, green: 20/255, blue: 18/255), location: 1.0)
    ],
    startPoint: .top,
    endPoint: .bottom
)
```

**Layout — top to bottom:**

```
Safe area top inset
  ↕ 60pt

Logo Area
  Orb (static, idle state, 80pt) OR wordmark
  "Saphan" — 38pt Bold (SF Pro Display), white
  "Translate feelings, not just words." — 15pt Regular Rounded, white.opacity(0.50)
  ↕ 52pt

Form Area
  Stack of input fields and action buttons, 32pt horizontal padding

  Email field
    Height: 52pt
    Background: Color.white.opacity(0.07)
    Border: Color.white.opacity(0.10) unfocused, #E07856 at 1.5pt lineWidth when focused
    Corner: 14pt
    Text: 16pt Regular, white
    Placeholder: white.opacity(0.35)

  Password field — same spec as email field

  ↕ 20pt

  Primary CTA — "Sign In"
    Height: 52pt, corner: 14pt, full width
    Background: LinearGradient(#E07856 → #D06A4A, topLeading → bottomTrailing)
    Text: 16pt Semibold Rounded, white
    Shadow: #E07856.opacity(0.30), radius: 12, y: 4
    Pressed: scale 0.975, shadow collapses

  ↕ 12pt

  "Don't have an account? Sign Up" — 14pt, white.opacity(0.50) + #E07856 for "Sign Up"

  ↕ 24pt

  Divider — "or continue with"
    Two lines: Color.white.opacity(0.12), height 1pt
    "or" text: 13pt Regular Rounded, white.opacity(0.40)

  ↕ 16pt

  Sign in with Apple button
    Height: 52pt, corner: 14pt, .white style (system-provided button)

  ↕ 10pt

  Sign in with Google button
    Height: 52pt, corner: 14pt
    Background: Color.white.opacity(0.08)
    Border: Color.white.opacity(0.12), 1pt
    Text: 16pt Medium Rounded, white
    Google "G" icon: use SF Symbol "g.circle.fill" tinted white, OR use a bundled Google logo asset

  ↕ 24pt

  "Continue as Guest" — ghost link
    14pt Medium Rounded, white.opacity(0.40), no border, no fill
    Underline optional
```

**Keyboard behavior:** Form scrolls up using ScrollView. Focused field border activates coral color simultaneously with focus ring appearance (no delay).

**Error state:** Replace the top logo area's subtitle text with the error message in `#FF6060`, 14pt, with a left-border accent bar in red. Do not use alert dialogs for auth errors — show them inline.

---

### 5.2 Voice Translation Screen

This is the heart of the app. It should feel like opening a luxury product. The interface should communicate: I am ready. Speak.

**Layout — full screen, ZStack:**

```
Layer 0 — Background
  Atmospheric gradient, full bleed, .ignoresSafeArea()
  Optional: very subtle animated particle or gradient shimmer (see §6)

Layer 1 — Content VStack (safe area aware)

  ── Top Bar ─────────────────────────────────────────
  Padding: horizontal 24pt, top 12pt
  Height: 48pt

  Left:  Status Pill (GlassPill component)
           State text: "Listening", "Translating", "Speaking", "Idle"
           Dot indicator: 6pt circle, color matches state semantic color
           e.g. "● Listening" — coral dot + "Listening" text

  Center: (empty — spacer)

  Right: Settings/Advanced icon button — 36pt circle, glass surface
           Icon: slider.horizontal.3, 16pt, white.opacity(0.70)

  ── Language Switcher ───────────────────────────────
  Margin top: 20pt
  Centered horizontally
  Language Switcher component (§4.4)
  280pt wide, 48pt tall

  ── Spacer ──────────────────────────────────────────
  Flexible spacer, minimum 24pt

  ── Voice Orb ───────────────────────────────────────
  Centered horizontally
  The orb stack (§4.1): glow → aura → blob → highlight → icon
  Total footprint: 240pt × 240pt (glow included)
  Orb core: 148pt

  Context Mode Pill — GlassPill, centered below orb
    Margin top: 12pt
    e.g. "Social" / "Dating" / "Travel"
    Tappable: opens context mode selector (bottom sheet, 3 columns of chips)

  ── Spacer ──────────────────────────────────────────
  Flexible spacer, minimum 24pt

  ── Transcript Display ──────────────────────────────
  Margin bottom: 16pt from Action Bar
  (see §4.5 spec — transparent background, over glow)
  Max height: 180pt, scrollable if exceeded
  Clips at top with a fade gradient: clear → background color over 24pt

  ── Action Bar ──────────────────────────────────────
  Margin bottom: 16pt from safe area bottom
  Centered, floating pill (see §4.2)

  ── Session Timer ───────────────────────────────────
  Below action bar, above home indicator
  Visible only when connected
  Transitions in with .transition(.opacity), delay 0.5s after connection
```

**Orientation of focus:** The orb sits in the vertical center of the screen. Above it is sparse context (language switcher, status). Below it is outcome (transcript). The user's eye naturally lands on the orb — nothing competes with it.

**The empty state moment:**
When first entering the screen (never connected), show only:
- Language switcher
- The orb in idle state
- Below the orb: hint text "Tap to begin translating" — 15pt Medium Rounded, white.opacity(0.35)
- Action bar with mic button

No scrollable history link, no status chips beyond the minimal top-left pill. Let the screen breathe.

---

### 5.3 Settings Screen

Settings uses the system appearance (light/dark), inheriting the existing `SaphanTheme.Palette`. The visual target is clean, restrained, iOS-native — not a departure into custom territory.

**Key changes from current implementation:**

**Header:**
```
Remove the NavigationStack large title.
Replace with a custom VStack header pinned to the top:

  Background: adaptive (palette.backgroundTop)
  Content:
    "Settings" — 26pt Bold Rounded, primary text
    User's display name or email — 14pt Regular Rounded, secondary text
  Padding: horizontal 20pt, vertical 16pt
  Divider: 1pt, palette.stroke
```

**Section styling:**

Replace `.listStyle(.insetGrouped)` with a custom ScrollView + VStack approach for more visual control:

```
Section header
  12pt Bold Rounded, secondaryText color, tracking +0.5pt, UPPERCASE
  Margin: bottom 8pt, top 24pt

Section container
  Background: palette.elevatedSurface (white in light, dark surface in dark)
  Corner radius: 16pt
  Padding: internal 0 (rows handle their own padding)
  Border: palette.stroke at 1pt
  Each row: 52pt tall, horizontal 16pt padding, divider between rows

Row spec
  Leading: SF Symbol icon, 22pt, tinted appropriately
  Title: 16pt Regular Rounded, primaryText
  Trailing: disclosure or control
  Pressed: background dims to palette.stroke.opacity(0.5)
```

**Account section — elevated treatment:**

The account card sits at the top of the Settings ScrollView as a dedicated card, not a list section:

```
Card: 16pt corner radius, elevatedSurface background, stroke border
  Avatar circle: 52pt, coral gradient fill, user initial in white 22pt Bold
  Name / email text
  Subscription badge: "Pro" pill in coral, or "Free" pill in gray
  Padding: 16pt

Below card: list sections continue
```

**Upgrade / Manage Subscription row** — use full-width CTA button style inside the card, not a list row, to create a premium visual hierarchy.

---

### 5.4 Paywall Screen

**Background:** Atmospheric dark gradient (same as Auth, Voice Translation).

**Layout — top to bottom:**

```
Close button — top right
  44pt × 44pt touch target
  Icon: xmark, 16pt, white.opacity(0.50)
  No background ring

↕ 40pt

Hero Area
  Custom orb visual — a decorative static version of the voice orb at 100pt
    Use the idle state orb colors but with a "gold" tint:
    Inner core: LinearGradient(#3D2A10 → #5A3C18)
    Outer glow: #DDA447 (amber/gold), opacity 0.40, blur 48pt
    This communicates "unlock" and premium without saying it

  "Saphan Pro" — 36pt Bold (SF Pro Display), white
  Margin top: 16pt from orb

  Subheadline — e.g. "Bridge any language. Anywhere."
  17pt Regular Rounded, white.opacity(0.60)
  Margin top: 8pt

↕ 40pt

Feature List
  3–4 key features (not all 6 — edit for scannability)
  Each feature row:
    Icon: 20pt, coral gradient
    Title: 15pt Semibold Rounded, white
    Description: 13pt Regular Rounded, white.opacity(0.55)
    Row height: 56pt
    No background box — features float on the atmospheric background
    Divider: Color.white.opacity(0.06), 1pt, full width

↕ 32pt

Pricing Area
  Plan cards — 2 cards side by side (Monthly and Yearly) OR stacked
  Preferred layout: stacked (easier to read, less cognitive load on mobile)

  Card spec:
    Background: Color.white.opacity(0.06)
    Border: Color.white.opacity(0.10) unselected; #E07856 at 2pt selected
    Corner: 16pt
    Padding: 16pt
    Selected state: background shifts to #E07856.opacity(0.12)
    "Best Value" badge on yearly: coral pill, 11pt Bold Rounded, white
    Price: 22pt Bold, white
    Period: 13pt Regular, white.opacity(0.55)
    Per-month equivalent: 12pt Regular, white.opacity(0.40)

↕ 28pt

Primary CTA — "Start Free Trial" or "Subscribe"
  Height: 56pt, full width (minus 48pt horizontal margins)
  Corner: 16pt
  Background: LinearGradient(#E07856 → #D06A4A, topLeading → bottomTrailing)
  Text: 17pt Semibold Rounded, white
  Shadow: #E07856.opacity(0.35), radius 16, y 6
  Glow: subtle — add a 60pt blur circle behind the button in coral

  Loading state: replace text with ProgressView, tint white

↕ 16pt

"Restore Purchases" — 14pt Regular, white.opacity(0.40)
  Centered, ghost link

Legal copy — two lines, 11pt Regular, white.opacity(0.25)
  "Auto-renewable. Cancel anytime in App Store settings."
  Privacy Policy · Terms of Service (linked in coral)
```

---

### 5.5 Onboarding

Onboarding uses the same atmospheric dark gradient. The goal is rapid value communication — 4 pages maximum, then language personalization, then paywall.

**Structural change from current:** Reduce from 8 pages (6 value + personalization + finish) to 4 pages:

```
Page 1 — Hook
  Icon: the voice orb animation (use the idle orb, 100pt)
  Headline: "Speak naturally. Be understood."
  Body: "Real-time voice translation that preserves tone, context, and emotion."

Page 2 — Proof of context
  Icon: SF Symbol "bubble.left.and.bubble.right.fill", 90pt, coral gradient
  Headline: "Built for real moments."
  Body: "Ordering food. Making friends. Navigating healthcare. Love across languages."

Page 3 — Differentiation
  Icon: SF Symbol "wand.and.stars", 90pt, coral gradient
  Headline: "Not just words. Feelings."
  Body: "Saphan picks the right tone for the situation — formal, casual, or warm — automatically."

Page 4 — Personalization
  (Language + Context picker, existing implementation retained)
  Headline: "Set your defaults."
  Body: "These can always be changed mid-conversation."

Then: "Continue to Plans" → Paywall
```

**Page layout (each page):**

```
Background: atmospheric gradient (full bleed)

Top bar: page dots — centered, 8pt circles, coral (active), white.opacity(0.25) (inactive)
         "Skip" text link — trailing, 14pt, white.opacity(0.40)

Page content: centered vertically in remaining space
  Icon / Orb — top of center grouping
  Headline — 30pt Bold (SF Pro Display), white, center-aligned, max 2 lines
  Body — 17pt Regular Rounded, white.opacity(0.65), center-aligned, max 4 lines
  Horizontal padding: 36pt

Bottom:
  Primary CTA button — "Continue" or "Let's Go" on final page
  Height: 52pt, coral gradient, 14pt corner radius, horizontal 32pt margins
```

**Transition between pages:** `.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))` with `.animation(.spring(response: 0.36, dampingFraction: 0.84))`. The orb on page 1 transitions with `.matchedGeometryEffect` into the orb on the Voice Translation screen after onboarding completes (aspirational — implement if feasible).

---

## 6. Motion & Animation

### 6.1 Foundational Principles

**Purposeful, never decorative.** Every animation answers a question: "What just happened?" or "What is happening right now?" No animations exist purely for visual pleasure.

**Physically grounded.** All animations use spring physics, not linear or ease curves, except for opacity fades which use `.easeInOut`. Springs make the interface feel alive and responsive.

**Fast in, slow out.** Entrance animations are slightly quicker than exit animations. The interface gets out of the way fast; it settles gently.

**The orb is always moving.** Even in idle, the orb breathes. This is intentional — it communicates that the system is alive and listening, even when not actively translating.

### 6.2 Core Animation Tokens

```swift
enum SaphanMotion {
    // Spring tokens — keep existing, add new ones:
    static let quickSpring = Animation.spring(response: 0.28, dampingFraction: 0.82)
    static let smoothSpring = Animation.spring(response: 0.36, dampingFraction: 0.84)
    static let bouncySpring = Animation.spring(response: 0.30, dampingFraction: 0.68)  // NEW: for orb reactions
    static let gentleSpring = Animation.spring(response: 0.50, dampingFraction: 0.90)  // NEW: for layout shifts

    // Ease tokens
    static let quickEase = Animation.easeInOut(duration: 0.20)
    static let slowFade  = Animation.easeInOut(duration: 0.40)  // NEW: transcript fade-in

    // Continuous animations (use withAnimation + repeatForever)
    static let breathe   = Animation.easeInOut(duration: 3.2).repeatForever(autoreverses: true)
    static let pulse     = Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)
}
```

### 6.3 Orb Animation States

```
IDLE — BREATHING
  Target: scale oscillates 1.00 ↔ 1.04
  Glow opacity: 0.20 ↔ 0.28
  Animation: .breathe (3.2s easeInOut, repeating)
  Blob morph: continuous slow phase advance

LISTENING — REACTIVE
  Scale base: 1.05 (spring transition from idle on connection)
  Amplitude-driven: audioLevel (0.0–1.0) maps to scale 1.05 → 1.16
    Use .animation(.linear(duration: 0.05)) for near-instant audio response
  Glow opacity: 0.25 + audioLevel * 0.15
  Blob morph: fast phase advance

TRANSITION idle → listening
  Duration: 0.4s, .smoothSpring
  Scale: 1.00 → 1.05 (spring overshoot)
  Glow color crossfade: teal → coral, .slowFade

TRANSITION listening → translating
  Scale: current → 1.02 (slight contract)
  Glow color crossfade: coral → amber, .quickEase
  Rotating arc overlay fades in: .opacity(0) → .opacity(1), .quickEase

TRANSLATION COMPLETE → speaking output
  Scale: 1.02 → 1.08 (small expand burst, spring)
  Glow color crossfade: amber → green, .smoothSpring
  Arc overlay fades out: .opacity(1) → .opacity(0), .quickEase
  One-time haptic: .impactOccurred(intensity: 0.5)

SESSION END
  Scale: current → 1.0, .smoothSpring
  All glow: fade to idle teal, .slowFade
  Orb transitions back to breathing
```

### 6.4 Transcript Appearance

```
New "YOU SAID" block:
  Slides in from bottom + fades: .transition(.opacity.combined(with: .move(edge: .bottom)))
  Animation: .smoothSpring

New translation block (below):
  Appears 0.3s after source transcript (delayed)
  Same transition
  Text content: appears character-by-character if streaming, or all-at-once with opacity crossfade if final
```

### 6.5 Screen Transitions

```
App launch → Auth
  Auth view fades in over dark splash: .opacity(0) → .opacity(1), .slowFade

Auth → Onboarding
  Slide: .move(edge: .trailing), .smoothSpring

Onboarding → Paywall
  Slide: .move(edge: .trailing), .smoothSpring

Paywall → Main Tab
  Scale + fade: incoming view scales 0.92 → 1.0 + opacity 0 → 1, .smoothSpring
  Outgoing fades: opacity 1 → 0, .quickEase

Sheet presentations (Language Picker, Advanced Controls, History)
  Use default SwiftUI .sheet() — system card presentation is correct here
  Customize only: .presentationCornerRadius(24) to match design language
```

### 6.6 Ambient Background Animation (Optional Enhancement)

On the Voice Translation screen, add a very subtle animated radial gradient shift behind the orb — not a particle system, but a slow movement of the warm spot in the background gradient:

```swift
// Conceptual implementation
@State private var ambientOffset: CGSize = .zero

// In body:
RadialGradient(
    colors: [Color(red: 224/255, green: 120/255, blue: 86/255).opacity(0.06), .clear],
    center: .init(x: 0.5 + ambientOffset.width / 400, y: 0.6 + ambientOffset.height / 800),
    startRadius: 0,
    endRadius: 260
)
.ignoresSafeArea()
.onAppear {
    withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
        ambientOffset = CGSize(width: 40, height: -30)
    }
}
```

This creates an imperceptible warmth shift behind the orb — like a candle flame moving slightly — that makes the screen feel genuinely alive without being distracting.

---

## 7. Interaction Patterns

### 7.1 Tap Hierarchy

Every interactive element on the Voice Translation screen must have a minimum 44pt touch target (existing `Constants.UI.minimumTapArea`). Elements smaller than 44pt visually must be padded with invisible touch area.

**Priority ordering (what a user should be able to reach with one thumb):**
1. Center mic/stop button — always accessible, centered bottom area
2. Language switcher — reachable from bottom
3. Status pill and settings — top area (secondary actions)

### 7.2 Haptic Feedback Patterns

```
Session starts (mic button tap):     .impactOccurred(intensity: 0.6) — medium
Translation complete:                .impactOccurred(intensity: 0.4) — light, one pulse
Language swap:                       .selectionChanged()
Context mode change:                 .selectionChanged()
Session ends:                        .impactOccurred(intensity: 0.7) — slightly firm
Error state:                         notification(.error)
Orb tap in idle (if no subscription): notification(.warning)
```

### 7.3 Long Press on Transcript Text

```
Source transcript or translation text:
  Long press → standard iOS text selection menu (already enabled via .textSelection(.enabled))
  Add a custom context menu action: "Copy Translation" that copies only the translated text
  Add: "Speak Again" — re-triggers TTS output for the last translation
```

### 7.4 Language Switcher Swap Behavior

When languages are swapped:
1. The swap arrow icon rotates 180° with `.bouncySpring`
2. Both language labels cross-dissolve (`.transition(.opacity)`) to their new values
3. If a session is active, the swap fires a new instruction to the realtime engine
4. One `.selectionChanged()` haptic fires at the moment of swap

### 7.5 Context Mode Quick Selector

Tapping the Context Mode pill below the orb opens a compact bottom sheet (`.presentationDetents([.height(280)])`) with a 3-column grid of context mode chips:

```
Sheet background: atmospheric dark gradient (not system material)
Header: "Conversation Context" — 17pt Semibold Rounded, white, center-aligned
Grid: 3 columns, 8pt gap

Chip spec:
  Background: Color.white.opacity(0.08) unselected
               contextTint(for: mode).opacity(0.20) selected
  Border: Color.white.opacity(0.10) unselected
           contextTint(for: mode) at 1.5pt selected
  Icon: SF Symbol, 20pt, contextTint color
  Label: mode.name, 13pt Semibold Rounded, white
  Height: 72pt
  Corner: 14pt
```

### 7.6 Conversation History Link

When history exists (`exchangeCount > 1`):
- Replace the empty state hint text with a minimal ghost pill link, horizontally centered above the transcript block
- "3 exchanges · View history" — 13pt Semibold Rounded, white.opacity(0.40)
- Tapping opens `.sheet` with `.presentationDetents([.large])`

Do not show this link during active speech (it would be distracting). Hide with `.opacity(isSpeaking || isOutputSpeaking ? 0 : 1)`.

### 7.7 Error Recovery

When `connectionState == .error`:
- The orb glow shifts to `#FF6060` (danger red) with a single 300ms pulse
- Status pill reads "Issue" in danger red
- A frosted glass notification bar slides in from the top of the screen (below the status bar):
  ```
  Background: Color(red: 215/255, green: 78/255, blue: 78/255).opacity(0.90) + blur
  Text: error message, 14pt Regular Rounded, white
  Dismiss: auto-dismiss after 4s, or tap to dismiss immediately
  Entry: .move(edge: .top) + .opacity, .smoothSpring
  ```
- The mic button in the action bar pulses once with danger red tint then returns to normal, indicating "tap me to retry"

---

## 8. SaphanTheme Extension Reference

The following additions to `VoiceTranslationTheme.swift` support the new design system:

```swift
// Add to SaphanTheme enum:

/// Atmospheric dark canvas — used for Voice, Auth, Onboarding, Paywall
static func atmosphericBackground() -> some ShapeStyle {
    LinearGradient(
        stops: [
            .init(color: Color(red: 14/255, green: 15/255, blue: 16/255), location: 0.0),
            .init(color: Color(red: 20/255, green: 19/255, blue: 22/255), location: 0.45),
            .init(color: Color(red: 24/255, green: 20/255, blue: 18/255), location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

/// Orb glow color for a given app state
static func orbGlowColor(connected: Bool, isSpeaking: Bool, isOutputSpeaking: Bool, isTranslating: Bool) -> Color {
    if isOutputSpeaking { return Color(red: 52/255, green: 199/255, blue: 89/255) }
    if isTranslating    { return Color(red: 221/255, green: 164/255, blue: 71/255) }
    if isSpeaking       { return brandCoral }
    if connected        { return brandCoral.opacity(0.80) }
    return Color(red: 78/255, green: 205/255, blue: 196/255)  // idle teal
}

/// Primary CTA with glow capability
static func primaryCTAWithGlow(cornerRadius: CGFloat = 14) -> some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(
            LinearGradient(
                colors: [
                    Color(red: 224/255, green: 120/255, blue: 86/255),
                    Color(red: 208/255, green: 106/255, blue: 74/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .shadow(color: brandCoral.opacity(0.35), radius: 16, y: 4)
}
```

---

## Appendix: Hex Color Reference Card

```
Brand Coral              #E07856
Brand Coral Dim          #D06A4A
Brand Warm Sand          #C1A28B
Canvas Deep              #0E0F10
Canvas Mid               #141618
Canvas Warm              #1C1A18
Surface Elevated (dark)  #242220
Text Primary (dark)      #ECEDEE
Text Secondary (dark)    #9BA1A6
Text Primary (light)     #1A1A1C
Text Secondary (light)   #6B7177
Background (light)       #FAFAF8
Background Alt (light)   #F2F0EC
Stroke (light)           #E0DDD8
Success Green            #34C759
Warning Amber            #DDA447
Danger Red               #FF6060
Orb Idle Glow Teal       #4ECDC4
```

---

*Saphan — "สะพาน" — bridge in Thai. This design system is the visual bridge between the technology inside and the human connection it serves.*
