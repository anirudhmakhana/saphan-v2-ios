# Saphan TODO

Last updated: 2026-02-25
Source of truth for this update: current local git diff in this repo.

## What is already done (from current code changes)
- [x] RevenueCat SDK-based subscription flow is wired in app code (`offerings`, `purchase`, `restore`, entitlement state updates, identity sync).
- [x] Subscription state is now injected as a shared environment object and used for routing/gating.
- [x] Paid-only route is implemented: `Splash -> Auth -> Onboarding -> Paywall(required) -> Main`.
- [x] Guest auth path was removed from auth UI/VM.
- [x] Paywall supports required mode, restore, and legal links (`Privacy`, `Terms`).
- [x] Weekly plan support was added to subscription product IDs and UI duration handling.
- [x] RevenueCat build vars are plumbed into `Info.plist` and constants resolution logic.
- [x] Onboarding was expanded to a longer value-first funnel with personalization step.
- [x] Settings/Voice views now check live subscription status instead of only local expiry assumptions.

## High-priority remaining work

### P0: RevenueCat + Payments (must finish before release)
- [ ] Validate sandbox purchase flows end-to-end on device for `weekly`, `monthly`, and `yearly` plans.
- [ ] Validate edge cases: cancel before purchase confirmation, pending payment, network drop during purchase, retry behavior.
- [ ] Validate restore flows on same device and new device with same Apple ID.
- [ ] Confirm entitlement unlock/lock propagation across app tabs and relaunch.
- [ ] Configure release/CI secrets for `SAPHAN_REVENUECAT_API_KEY` and `SAPHAN_REVENUECAT_ENTITLEMENT_ID`.
- [ ] Remove/avoid test API keys in project build settings for release builds.
- [ ] Confirm App Store Connect product setup and mapping exactly matches app product IDs.

### P0: Legal + Compliance
- [ ] Verify production `Privacy Policy` and `Terms` URLs are final, reachable, and compliant.
- [ ] Complete App Store Connect privacy disclosures (data collection + tracking answers).
- [ ] Add and test in-app account deletion flow (required for account-based apps).
- [ ] Prepare App Review notes: login methods, subscription test steps, keyboard full-access behavior.
- [ ] Ensure support URL and policy URLs in App Store Connect metadata are correct.

### P0: Translation quality + flow closure
- [ ] Implement voice setting-change reconnect UX (explicit TODO still in code for voice change while connected).
- [ ] Wire voice settings changes through VM update methods consistently (target language/context/voice update path).
- [ ] Ensure PTT mode is fully exposed in current UI (VM logic exists; verify/finish user-facing controls).
- [ ] Record voice session usage with backend `recordSession(...)` at session teardown.
- [ ] Add keyboard translation flow QA: full access disabled/enabled, auth missing, API error, quota/rate limit.

## Medium-priority remaining work

### P1: Translation feature polish
- [ ] Wire keyboard `autoTranslate` preference to real behavior.
- [ ] Decide and implement keyboard translation count tracking (placeholder currently).
- [ ] Use keyboard-specific language list consistently in keyboard pickers (if product requirement remains 12-language keyboard scope).
- [ ] Persist/load default voice translation settings (language/context/voice) from preferences into voice VM.
- [ ] Add funnel + translation analytics events (`onboarding_*`, `paywall_*`, `purchase_*`, `auth_success`).

### P1: QA matrix and release stability
- [ ] Run fresh install QA path.
- [ ] Run upgrade-from-previous-build QA path.
- [ ] Run auth/subscription cross-state regression pass.
- [ ] Run keyboard extension app-group and token-sharing validation on real device.
- [ ] Produce release candidate signoff checklist and execute it.

## App Store screenshots + listing assets

### Screenshot production checklist
- [ ] Define screenshot device matrix (minimum: 6.7", 6.5", 5.5" if needed by target deployment/listing strategy).
- [ ] Capture core funnel screens: Splash, Auth, long Onboarding, Required Paywall.
- [ ] Capture product value screens: Voice Translation live state, Advanced controls, Keyboard extension, Settings.
- [ ] Ensure no placeholder text, debug labels, test emails, or internal identifiers appear in screenshots.
- [ ] Localize screenshots if planning multi-locale listing.
- [ ] Final review pass for consistency (fonts, capitalization, CTA labels, pricing text).

### Metadata packaging
- [ ] Finalize App Store description, subtitle, keywords, and promo text aligned with paid-only positioning.
- [ ] Provide final support contact and support URL.
- [ ] Confirm subscription marketing text in App Store Connect matches in-app naming.

## Suggested execution order
1. Finish `P0 RevenueCat + Payments` validation and secrets.
2. Close `P0 Legal + Compliance` gaps.
3. Close `P0 Translation` flow blockers.
4. Generate App Store screenshots + metadata package.
5. Run full QA matrix and release signoff.
