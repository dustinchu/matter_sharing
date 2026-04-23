# Changelog

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
