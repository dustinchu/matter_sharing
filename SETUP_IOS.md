# iOS Setup Guide

> **Apple Home only?** You only need Steps 1, 2 (Runner target capabilities only), and 3.
> **Google Home?** Complete all steps including Step 0.

---

## Step 0: Download Google Home SDK (Google Home only)

The Google Home SDK xcframeworks are not included in the plugin due to file size limits.
Download them from the [Google Home Developer Console](https://developers.home.google.com/apis/ios/sdk?authuser=2) and place them inside **your app's** `ios/Frameworks/` directory:

```text
YOUR_APP/
  ios/
    Frameworks/
      GoogleHomeSDK.xcframework
      GoogleHomeTypes.xcframework
```

After placing the files, run `pod install` again.

> **Minimum iOS deployment target:** This plugin requires iOS 16.1+. Make sure your project targets at least iOS 16.1 in both `ios/Podfile` and Xcode (Runner target -> Build Settings -> iOS Deployment Target).
> In `ios/Podfile`: `platform :ios, '16.1'`
> In Xcode: Runner target -> Build Settings -> search `IPHONEOS_DEPLOYMENT_TARGET` -> set to `16.1`

---

## Step 1: Xcode - Runner Target Capabilities

Open your project in Xcode, select the **Runner** target, go to **Signing & Capabilities**.

### 1-1. Add App Groups

1. Click **+ Capability** -> select **App Groups**
2. Under App Groups, click **+**
3. Enter: `group.YOUR_BUNDLE_ID` (e.g. `group.com.yourcompany.yourapp`)
4. Xcode will automatically register this in your Apple Developer account and update your provisioning profile

### 1-2. Add HomeKit

1. Click **+ Capability** -> select **HomeKit**

### 1-3. Add Matter Allow Setup Payload

1. Click **+ Capability** -> search for **Matter Allow Setup Payload**, select it

After adding all three, your `Runner.entitlements` should contain:

```xml
<key>com.apple.developer.homekit</key>
<true/>
<key>com.apple.developer.matter.allow-setup-payload</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
  <string>group.YOUR_BUNDLE_ID</string>
</array>
```

---

## Step 2: Xcode - Info.plist (Runner target)

In Xcode, open `Runner/Info.plist` and add:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Required to connect to Matter devices on the local network.</string>
<key>NSBonjourServices</key>
<array>
  <string>_meshcop._udp</string>
  <string>_matter._tcp</string>
  <string>_matterc._udp</string>
  <string>_matterd._udp</string>
  <string>_http._tcp</string>
  <string>_googcrossdevice._tcp</string>
  <string>_googlecrossdevice._tcp</string>
  <string>_ghp._tcp</string>
  <string>_mqtt._tcp</string>
</array>
```

---

## Step 3: AppDelegate.swift

Replace the contents of `ios/Runner/AppDelegate.swift` with the following. **You never need to edit this file again** - credentials are read from Info.plist (Step 5).

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

---

## Step 4: Matter Extension (Google Home only)

The Matter Extension cannot be bundled in the plugin - you must create it as a separate Xcode target.

### 4-1. Create the target

1. In Xcode: **File** -> **New** -> **Target**
2. Select **Matter Accessory Setup Extension**
3. Set:
   - Product Name: `MatterExtension`
   - Bundle ID: `YOUR_BUNDLE_ID.MatterExtension`
   - Team: your Apple Developer Team

### 4-2. Add the same capabilities to the extension target

Select the **MatterExtension** target -> **Signing & Capabilities**:

1. **+ Capability** -> **App Groups** -> select the same group you created in Step 1 (`group.YOUR_BUNDLE_ID`)
2. **+ Capability** -> **HomeKit**
3. **+ Capability** -> **Matter Allow Setup Payload**

Xcode updates the provisioning profile automatically.

### 4-3. Add files to the MatterExtension target

First, run the following in your project root to generate the extension files:

```sh
flutter pub get
cd ios && pod install
```

After running `pod install`, the following files are automatically generated in `ios/MatterExtension/` with your App Group already filled in:

- `RequestHandler.swift`
- `Info.plist`
- `MatterExtension.entitlements`

In Xcode, add these files to the MatterExtension target:

1. Right-click the **MatterExtension** group in the project navigator -> **Add Files to "Runner"**
2. Select all three files from `ios/MatterExtension/`
3. Make sure **Target Membership** is set to **MatterExtension only** (not Runner)

### 4-4. Add the same `MatterSharing*` keys to the extension's Info.plist

The extension runs in a separate process and reads **its own** `Info.plist`, not Runner's. If the keys are missing here, the extension cannot restore the Google Home OAuth session and the user will be prompted for Google Home permission **a second time** during commissioning.

Open `ios/MatterExtension/Info.plist` and add the same four keys you will set in Step 5 for Runner:

```xml
<key>MatterSharingTeamID</key>
<string>YOUR_APPLE_TEAM_ID</string>
<key>MatterSharingClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com</string>
<key>MatterSharingServerClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com</string>
<key>MatterSharingAppGroup</key>
<string>group.YOUR_BUNDLE_ID</string>
```

The values must be identical to Runner's so the extension's `GoogleHomeSDK` instance can find the session stored by the main app in the shared App Group.

---

## Step 5: Google Home Credentials (Google Home only)

Open `ios/Runner/Info.plist` and add your credentials. **This is the only place you fill in your own values.**

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

**Where to find these values:**

| Key                           | Where to find it                                                                                                                                                                         |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MatterSharingTeamID`         | Xcode -> Runner target -> Signing & Capabilities -> Team ID shown next to your team name, or [developer.apple.com/account](https://developer.apple.com/account) -> Membership -> Team ID |
| `MatterSharingClientID`       | Google Cloud Console -> APIs & Services -> Credentials -> your **iOS** OAuth 2.0 Client ID (see Step 6)                                                                                  |
| `MatterSharingServerClientID` | Google Cloud Console -> APIs & Services -> Credentials -> your **Web** OAuth 2.0 Client ID (different from the iOS one; create a "Web application" client if you don't have one)         |
| `MatterSharingAppGroup`       | The group identifier you created in Step 1                                                                                                                                               |

Set `MatterSharingEnabled` to `<false/>` or remove these keys entirely if you only use Apple Home.

---

## Step 6: Google Cloud Console (Google Home only)

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create or select a project
3. Enable **Google Home API**
4. Go to **APIs & Services** -> **Credentials** -> **Create Credentials** -> **OAuth 2.0 Client ID**
   - Application type: **iOS**
   - Bundle ID: `YOUR_BUNDLE_ID`
5. Copy the iOS Client ID (format: `XXXXXXXXX.apps.googleusercontent.com`) into `MatterSharingClientID` in Info.plist (Step 5)
6. Create a second OAuth 2.0 Client ID with Application type **Web application** - copy that into `MatterSharingServerClientID`
7. Go to [Google Home Developer Console](https://console.home.google.com)
8. Create a Matter integration, configure the OAuth client, and set your **CSA Vendor ID (VID)** - without a registered VID, Google Home will reject commissioning

---

## Before Sharing: Open Commissioning Window (OCW)

Before calling `shareToAppleHome` or `shareToGoogleHome`, the Matter device must have its **Commissioning Window open**.

In the Matter specification this is called **Open Commissioning Window (OCW)**. Your device firmware or your app must trigger this on the device before initiating the share flow. Common ways to do this:

- Call `openPairingWindow` / `openBasicCommissioningWindow` via your Matter controller SDK
- Use a manufacturer app or BLE setup tool to open the window
- Some devices open the window automatically on first boot (factory reset state)

If the commissioning window is not open, the share will fail with `COMMISSION_FAILED` or `SHARE_FAILED`.

If the user closes the Google Home or Apple Home system sheet without completing commissioning, the plugin throws `MatterSharingException` with code `MatterSharingErrorCode.cancelled` - treat this as a benign user action, not an error.
