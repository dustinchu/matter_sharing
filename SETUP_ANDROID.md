# Android Setup Guide

## Step 1: Add Google Play Services Home

In `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.google.android.gms:play-services-home:16.0.0-beta1'
}
```

## Step 2: AndroidManifest.xml

No special permissions are required. Google Play Services handles all device discovery (mDNS) and commissioning internally via its own Intent flow.

In `android/app/src/main/AndroidManifest.xml`, add the commissioning activity:

```xml
<manifest>
    <application>
        <!-- Required for Google Home commissioning UI -->
        <activity
            android:name="com.google.android.gms.home.matter.commissioning.CommissioningActivity"
            android:exported="true" />
    </application>
</manifest>
```

## Step 3: Google Home Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create or select a project (same project as iOS if sharing)
3. Enable **Google Home API**
4. Go to [Google Home Developer Console](https://console.home.google.com)
5. Create a Matter integration and configure your CSA Vendor ID

## Usage

### Commission a new device (no existing fabric)

The device must have its **Commissioning Window open** before calling this method.
In Matter this is called **Open Commissioning Window (OCW)**. Your device firmware or your app must call `openPairingWindow` / `openBasicCommissioningWindow` on the device before initiating sharing.

```dart
// Device must have OCW open first
await MatterSharing.shareToGoogleHome(
  onboardingPayload: 'MT:Y.K90AFN00KA0648G00',
);
```

### Share an already-commissioned device (multi-fabric / shareDevice)

If the device is already commissioned into your app's fabric and you want to also add it to Google Home, open a commissioning window on the device first, then pass the window parameters.

`discriminator` and `passcode` are the credentials of the open commissioning window on the device:

- **discriminator** - identifies which device to connect to when multiple Matter devices are broadcasting
- **passcode** - the pairing password used to establish an encrypted PASE session with the device

`vendorId`, `productId`, and `deviceType` describe the device to Google Home. These values come from your device's Matter firmware configuration:

- **vendorId** - your CSA-assigned Vendor ID (e.g. `0xFFF1` for test devices)
- **productId** - your product ID (e.g. `0x8000`)
- **deviceType** - the Matter device type ID (e.g. `0x0202` for air conditioner, `0x0100` for on/off light)

> **iOS note:** These parameters (`discriminator`, `passcode`, `vendorId`, `productId`, `deviceType`) are Android-only. On iOS, the system Matter framework handles device discovery and connection automatically from the `onboardingPayload`. You only need to pass `onboardingPayload` on iOS.

```dart
await MatterSharing.shareToGoogleHome(
  onboardingPayload: 'MT:Y.K90AFN00KA0648G00',
  // Android only - open commissioning window credentials
  discriminator: 3840,
  passcode: 20202021,
  durationSeconds: 900,
  // Android only - device descriptor (from your firmware configuration)
  vendorId: 0xFFF1,
  productId: 0x8000,
  deviceType: 0x0202,  // air conditioner
);
```

If `vendorId`, `productId`, or `deviceType` are omitted, the plugin falls back to test defaults (`0xFFF1`, `0x8000`, `0x0300`).

### Common Matter device type IDs

| Device | deviceType |
| ------ | ---------- |
| On/Off Light | `0x0100` |
| Dimmable Light | `0x0101` |
| Air Conditioner | `0x0202` |
| Thermostat | `0x0301` |
| Door Lock | `0x000A` |
| Window Covering | `0x0202` |

## Error Handling

```dart
try {
  await MatterSharing.shareToGoogleHome(onboardingPayload: payload);
} on MatterSharingException catch (e) {
  switch (e.code) {
    case MatterSharingErrorCode.cancelled:
      // User closed the Google Home UI
      break;
    case MatterSharingErrorCode.googleHomeError:
      // Google Play Services error - check e.message
      break;
    default:
      break;
  }
}
```

## Requirements

- Android 8.1+ (API 27+)
- Google Play Services installed on the device
- A Google Home Hub (Nest Hub, Nest Mini, Chromecast, etc.) on the same local network as the Matter device
