# Saphan Brand System (Extracted from `live-translator-mobile`)

This document captures the current visual branding used in `live-translator-mobile`, based on implementation files (not mockups).

## Sources

- `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/constants/Colors.ts`
- `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/app/(auth)/welcome.tsx`
- `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/app/(auth)/login.tsx`
- `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/app/(auth)/signup.tsx`
- `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/app/(tabs)/index.tsx`
- `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/app/(tabs)/settings.tsx`
- `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/app/subscription.tsx`
- `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/app/_layout.tsx`
- `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/app.json`

## Brand Identity

- App name: `Saphan` / `Saphan Translator`
- Primary tagline in auth flow: `Break language barriers instantly`
- Subscription product name: `Saphan Premium`
- Logo asset: `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/assets/images/logo.png` (1024x1024)

## Core Brand Colors

These are the canonical brand colors repeatedly used across auth, tabs, settings, and subscription:

1. `Sunset Coral` - `#E07856` (primary accent, CTA, selected states)
2. `River Clay Gold` - `#C1A28B` (secondary accent)
3. `Deep Charcoal` - `#2C2C2E` (dark surfaces, dark CTA for "Stop")
4. `Warm White` - `#F9F7F4` (light cards/background tint)
5. `System White` - `#FFFFFF` (base light background and text on dark accents)

## Theme Tokens (Light/Dark)

From `constants/Colors.ts`:

### Light theme

- `text`: `#2C2C2E`
- `background`: `#FFFFFF`
- `tint`: `#E07856`
- `icon`: `#687076`
- `tabIconDefault`: `#687076`
- `tabIconSelected`: `#E07856`
- `primary`: `#E07856`
- `secondary`: `#C1A28B`
- `cardBackground`: `#F9F7F4`
- `bubbleUser`: `#F9F7F4`
- `bubbleTranslation`: `rgba(224, 120, 86, 0.1)`

### Dark theme

- `text`: `#ECEDEE`
- `background`: `#151718`
- `tint`: `#E07856`
- `icon`: `#9BA1A6`
- `tabIconDefault`: `#9BA1A6`
- `tabIconSelected`: `#E07856`
- `primary`: `#E07856`
- `secondary`: `#C1A28B`
- `cardBackground`: `#1E1E1E`
- `bubbleUser`: `#2C2C2E`
- `bubbleTranslation`: `rgba(224, 120, 86, 0.2)`

## Supporting UI Colors

Used for state and utility styling:

- Premium/success green: `#34C759` (subscription + active indicators)
- Signup strength success: `#4CAF50`
- Error red: `#FF4444` / `#ff4444`
- Warning amber: `#ffaa00`
- Mid-success lime: `#88cc00`
- Modal dark surface: `#1C1C1E`
- Disabled gradient grays: `#666`, `#555`

## Brand Gradients and Transparent Overlays

Common gradients:

1. Auth background gradient: `[#2C2C2E, #1A1A1A, #0F0F0F]`
2. Primary CTA gradient: `[#E07856, #D06A4A]`
3. Orb overlays:
   - Coral orb: `#E07856 -> transparent`
   - Gold orb: `#C1A28B -> transparent`

Common translucent overlays:

- `rgba(255,255,255,0.1)` / `rgba(255,255,255,0.15)` for frosted dark surfaces
- `rgba(0,0,0,0.05)` and `rgba(0,0,0,0.5)` for separators and modal scrim
- `rgba(224,120,86,0.1~0.3)` for coral-tinted badges and borders

## Typography (What Is Actually Used)

## Primary runtime typography

- The app visually uses platform system fonts with `fontWeight` and `fontSize` (no global custom `fontFamily` applied in UI components).
- On iOS this renders as SF Pro system typography.

Common weights used:

- `700` for primary headings/CTA labels
- `600` for section titles/buttons
- `500` for secondary labels

Common size scale:

- `12, 13, 14, 15, 16, 17, 18, 20, 22, 24, 28, 32, 42`

Special numeric style:

- `fontVariant: ['tabular-nums']` used for session timer values.

## Loaded but not currently applied font

- `SpaceMono-Regular.ttf` exists and is loaded in `app/_layout.tsx` as `SpaceMono`.
- Current app screens do not set `fontFamily: 'SpaceMono'`, so this font is effectively unused in the active UI.

## Brand Assets

- Primary logo: `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/assets/images/logo.png`
- App icon: `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/assets/images/icon.png`
- Adaptive icon: `/Users/anirudhmakhana/Documents/krsnalabs/live-translator-mobile/assets/images/adaptive-icon.png`
- Splash background color in Expo config: `#ffffff`

## Recommended Mapping for Native iOS (`saphan`)

If you want parity with RN branding, define these semantic tokens in Swift:

1. `brandPrimary = #E07856`
2. `brandSecondary = #C1A28B`
3. `brandDark = #2C2C2E`
4. `brandWarmSurface = #F9F7F4`
5. `premiumSuccess = #34C759`

And keep dynamic palettes equivalent to the Light/Dark token tables above.

