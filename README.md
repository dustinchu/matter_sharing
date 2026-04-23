# matter_sharing

Share Matter smart home devices to Apple Home and Google Home from your Flutter app.

## Features

- iOS: Share to Apple Home (iOS 16.1+)
- iOS: Share to Google Home (iOS 16.1+, requires Google Home Hub)
- Android: Share to Google Home (Android 8.1+, requires Google Home Hub)

## Quick Start

```dart
import 'package:matter_sharing/matter_sharing.dart';

// Share to Apple Home (iOS only)
await MatterSharing.shareToAppleHome(
  onboardingPayload: 'MT:Y.K90AFN00KA0648G00',
);

// Share to Google Home (iOS + Android)
await MatterSharing.shareToGoogleHome(
  onboardingPayload: 'MT:Y.K90AFN00KA0648G00',
);
```

## Setup

- [iOS Setup Guide](SETUP_IOS.md)
- [Android Setup Guide](SETUP_ANDROID.md)

## iOS Google Home Configuration

Add credentials to `ios/Runner/Info.plist` - no Swift code changes needed.

```xml
<key>MatterSharingEnabled</key>
<true/>
<key>MatterSharingTeamID</key>
<string>YOUR_APPLE_TEAM_ID</string>
<key>MatterSharingClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com</string>
<key>MatterSharingServerClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com</string>
<key>MatterSharingAppGroup</key>
<string>group.YOUR_BUNDLE_ID</string>
```

Then in `AppDelegate.swift` (copy once, never edit again):

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    MatterSharingPlugin.configureGoogleHomeFromPlist()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Set `MatterSharingEnabled` to `<false/>` or omit the key to disable Google Home.

## API

### `MatterSharing.shareToAppleHome`

```dart
static Future<void> shareToAppleHome({required String onboardingPayload})
```

Shares a Matter device to Apple Home using `HMAccessorySetupManager`. iOS presents a system UI for the user to choose a home.

### `MatterSharing.shareToGoogleHome`

```dart
static Future<void> shareToGoogleHome({
  required String onboardingPayload,
  int? discriminator,   // Android only
  int? passcode,        // Android only
  int? durationSeconds, // Android only
  int? vendorId,        // Android only
  int? productId,       // Android only
  int? deviceType,      // Android only
})
```

Shares a Matter device to Google Home. On iOS, requires Google Home SDK and a Matter Extension target. On Android, uses `play-services-home`.

**iOS:** Only `onboardingPayload` is needed. The system Matter framework handles device discovery automatically.

**Android:** When sharing a device already in your app's fabric (multi-fabric), pass the open commissioning window credentials and device descriptor:

- `discriminator` / `passcode` - credentials of the open commissioning window on the device
- `vendorId` / `productId` / `deviceType` - device descriptor from your firmware configuration; defaults to `0xFFF1` / `0x8000` / `0x0300` if omitted

```dart
// iOS - payload only
await MatterSharing.shareToGoogleHome(
  onboardingPayload: 'MT:Y.K90AFN00KA0648G00',
);

// Android - multi-fabric shareDevice flow
await MatterSharing.shareToGoogleHome(
  onboardingPayload: 'MT:Y.K90AFN00KA0648G00',
  discriminator: 3840,
  passcode: 20202021,
  durationSeconds: 900,
  vendorId: 0xFFF1,
  productId: 0x8000,
  deviceType: 0x0202, // air conditioner
);
```

Common `deviceType` values:

| Device | deviceType |
| ------ | ---------- |
| On/Off Light | `0x0100` |
| Dimmable Light | `0x0101` |
| Air Conditioner | `0x0202` |
| Thermostat | `0x0301` |
| Door Lock | `0x000A` |

### `MatterSharing.configureGoogleHome` (advanced / legacy)

```dart
static Future<void> configureGoogleHome(GoogleHomeConfig config)
```

**iOS only.** Configures the Google Home SDK at runtime from Dart. Use this only if you cannot use the `pubspec.yaml` approach. Must be called before `shareToGoogleHome`.

```dart
await MatterSharing.configureGoogleHome(GoogleHomeConfig(
  teamID: 'YOUR_APPLE_TEAM_ID',
  clientID: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com',
  serverClientID: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com',
  appGroup: 'group.YOUR_BUNDLE_ID',
));
```

Note: `Home.configure()` must run before the Flutter engine is fully ready. For most apps the `pubspec.yaml` + `configureGoogleHomeFromPlist()` approach is more reliable.

## Before Sharing: Open Commissioning Window (OCW)

The Matter device must have its **Commissioning Window open** before calling any share method. In the Matter specification this is called **Open Commissioning Window (OCW)**. Trigger `openPairingWindow` / `openBasicCommissioningWindow` on the device via your Matter controller before initiating the share flow. If the window is not open, commissioning will fail.

## Error Handling

The plugin throws `MatterSharingException` (not `PlatformException`). Catch it by type and switch on `MatterSharingErrorCode`:

```dart
try {
  await MatterSharing.shareToGoogleHome(onboardingPayload: payload);
} on MatterSharingException catch (e) {
  switch (e.code) {
    case MatterSharingErrorCode.noStructure:
      // No Google Home found - user needs to set up a home in the Google Home app
      break;
    case MatterSharingErrorCode.alreadyCommissioned:
      // Device already added to this Google Home - remove it first
      break;
    case MatterSharingErrorCode.commissionFailed:
      // Commissioning failed - check e.message and e.details for native error
      break;
    case MatterSharingErrorCode.cancelled:
      // User closed the UI
      break;
    default:
      print('${e.code}: ${e.message}');
  }
}
```

| `MatterSharingErrorCode` | Raw code | Platform | Meaning |
| --- | --- | --- | --- |
| `invalidArgs` | `INVALID_ARGS` | iOS/Android | Missing or invalid method arguments |
| `invalidPayload` | `INVALID_PAYLOAD` | iOS | Could not parse onboarding payload |
| `notConfigured` | `NOT_CONFIGURED` | iOS | Google Home SDK not configured |
| `sdkNotLinked` | `SDK_NOT_LINKED` | iOS | GoogleHomeSDK not available |
| `noStructure` | `NO_STRUCTURE` | iOS | No Google Home structure found |
| `alreadyCommissioned` | `ALREADY_COMMISSIONED` | iOS | Device already added to this Google Home |
| `commissionFailed` | `COMMISSION_FAILED` | iOS | Google Home commissioning failed |
| `appleHomeFailed` | `SHARE_FAILED` | iOS | Apple Home sharing failed |
| `googleHomeError` | `GOOGLE_HOME_ERROR` | Android | Google Play Services error |
| `cancelled` | `CANCELLED` | iOS/Android | User closed the Google Home / Apple Home system sheet |
| `unsupported` | `UNSUPPORTED` | iOS | Requires iOS 16.1+ |
| `unknown` | _(other)_ | iOS/Android | Unexpected error code |

## Requirements

### iOS

- iOS 16.1+ (set `platform :ios, '16.1'` in `ios/Podfile` and `IPHONEOS_DEPLOYMENT_TARGET = 16.1` in Xcode)
- Apple Developer Account with Matter Allow Setup Payload capability
- For Google Home: Matter Extension target in your Xcode project (Google Home SDK is bundled)

### Android

- Android 8.1+ (API 27+)
- `com.google.android.gms:play-services-home` dependency

## Important Notes

- Google Home requires a Google Home Hub (Nest Hub, Nest Mini, Chromecast, etc.) on the same local network
- The Matter Extension cannot be bundled in the plugin - you must add it as a separate Xcode target (see [iOS Setup Guide](SETUP_IOS.md))
- The Apple Developer Portal App Group must be created manually
- `configureGoogleHome` is a no-op on Android
