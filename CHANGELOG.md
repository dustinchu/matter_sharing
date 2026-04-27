# Changelog

## 0.1.6

- iOS: Fix `com.apple.MatterSupport` error 1 being misreported as `MatterSharingErrorCode.cancelled`. iOS uses the same code 1 for fabric conflicts (AddNOC err=7e), fail-safe timer expiry, and extension failures, so treating it as a cancel hid real commissioning failures from apps. Cancellation is now detected only from concrete underlying errors (`NSCocoaErrorDomain`/`NSUserCancelledError`, `HMErrorDomain` 38, POSIX `ECANCELED`). Affects both Google Home and Apple Home sharing.

## 0.1.5

- iOS: Fix duplicate Google Home permission prompt on first install. Extension process now calls `Home.configure()` + `Home.restoreSession()` before using `HomeMatterCommissioner`, so it reuses the OAuth session already granted by the main app.
- iOS: Remove the `prepareForMatterCommissioning` pre-warm from `Home.configure()`. Pre-warm could race with the user-initiated share flow and cause `ASWebAuthenticationSession` continuation to be resumed twice, crashing the app.
- docs: SETUP_IOS - document that the extension target's Info.plist must include the same `MatterSharing*` keys as the Runner target (extension runs in a separate process and reads its own Info.plist).

## 0.1.4

- iOS: Detect user cancellation of the Google Home and Apple Home system sheets and return `MatterSharingErrorCode.cancelled` instead of `commissionFailed` / `appleHomeFailed`. Matches Android behavior.
- docs: `MatterSharingErrorCode.cancelled` is no longer Android-only; update README error table and SETUP guides.

## 0.1.3

- docs: Add `alreadyCommissioned` error code to README error table and example.

## 0.1.2

- iOS: Fix double Google sign-in prompt on first install by pre-warming `prepareForMatterCommissioning` after session restore.
- iOS: Detect duplicate device commissioning (HFErrorDomain Code=33) and return `MatterSharingErrorCode.alreadyCommissioned` instead of a generic error.

## 0.1.1

- iOS: Fix `GoogleHomeSDK not available` error when installed from pub.dev.
- iOS: Add Swift Package Manager (SPM) support.
- Bump minimum Flutter version to 3.41.0.

## 0.1.0

- Initial release.
- iOS: Share to Apple Home via `HMAccessorySetupManager`.
- iOS: Share to Google Home via Google Home SDK + Matter Extension.
- Android: Share to Google Home via `play-services-home`.
