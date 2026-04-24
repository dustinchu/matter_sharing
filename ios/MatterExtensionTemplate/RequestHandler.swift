import Matter
import MatterSupport
import GoogleHomeSDK

// MARK: - Configuration
// TODO: Change this to your App Group identifier (must match Runner.entitlements)
private let appGroup = "group.YOUR_BUNDLE_ID"  // <-- CHANGE THIS

@available(iOSApplicationExtension 16.1, *)
class RequestHandler: MatterAddDeviceExtensionRequestHandler {

  // One-time Home.configure() + restoreSession() in this extension process so
  // GoogleHomeSDK can reuse the OAuth tokens already granted by the main app.
  // Without this, the SDK inside the extension sees no session and re-prompts
  // the user for Google Home permission a second time.
  private static var didConfigureHome = false

  private func ud() -> UserDefaults? {
    return UserDefaults(suiteName: appGroup)
  }

  private func mode() -> String {
    return ud()?.string(forKey: "*#extCommissioningMode") ?? "legacy"
  }

  private func ensureHomeConfigured() async {
    guard !Self.didConfigureHome else { return }

    guard let info = Bundle.main.infoDictionary,
          let teamID = info["MatterSharingTeamID"] as? String, !teamID.isEmpty,
          let clientID = info["MatterSharingClientID"] as? String, !clientID.isEmpty,
          let serverClientID = info["MatterSharingServerClientID"] as? String, !serverClientID.isEmpty,
          let appGroupFromPlist = info["MatterSharingAppGroup"] as? String, !appGroupFromPlist.isEmpty
    else {
      NSLog("[MatterExt] Home.configure skipped: missing MatterSharing* keys in extension Info.plist")
      return
    }

    await MainActor.run {
      Home.configure {
        $0.teamID = teamID
        $0.clientID = clientID
        $0.serverClientID = serverClientID
        $0.sharedAppGroup = appGroupFromPlist
      }
    }
    _ = await Home.restoreSession()
    Self.didConfigureHome = true
    NSLog("[MatterExt] Home.configure + restoreSession done")
  }

  override func validateDeviceCredential(
    _ deviceCredential: MatterAddDeviceExtensionRequestHandler.DeviceCredential
  ) async throws {
    // Accept all device credentials
  }

  override func selectWiFiNetwork(
    from wifiScanResults: [MatterAddDeviceExtensionRequestHandler.WiFiScanResult]
  ) async throws -> MatterAddDeviceExtensionRequestHandler.WiFiNetworkAssociation {
    guard let ud = ud() else { return .defaultSystemNetwork }

    // Use preset WiFi if the main app wrote one before calling perform()
    if ud.bool(forKey: "*#extPresetWifiReady"),
       let presetStr = ud.string(forKey: "*#extPresetWifi"),
       let presetData = presetStr.data(using: .utf8),
       let preset = try? JSONSerialization.jsonObject(with: presetData) as? [String: String],
       let ssid = preset["ssid"], !ssid.isEmpty,
       let ssidData = ssid.data(using: .utf8) {
      let password = preset["password"] ?? ""
      return .network(ssid: ssidData, credentials: password.data(using: .utf8) ?? Data())
    }

    return .defaultSystemNetwork
  }

  override func selectThreadNetwork(
    from threadScanResults: [MatterAddDeviceExtensionRequestHandler.ThreadScanResult]
  ) async throws -> MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation {
    return .defaultSystemNetwork
  }

  override func commissionDevice(
    in home: MatterAddDeviceRequest.Home?,
    onboardingPayload: String,
    commissioningID: UUID
  ) async throws {
    let currentMode = mode()
    NSLog("[MatterExt] commissionDevice called, mode: %@", currentMode)

    if currentMode == "google" {
      await ensureHomeConfigured()
      let commissioner = try HomeMatterCommissioner(appGroup: appGroup)
      try await commissioner.commissionMatterDevice(onboardingPayload: onboardingPayload)
    }
    // For Apple Home (HMAccessorySetupManager flow), iOS handles commissioning directly.
  }

  override func rooms(
    in home: MatterAddDeviceRequest.Home?
  ) async -> [MatterAddDeviceRequest.Room] {
    if mode() == "google" {
      await ensureHomeConfigured()
      if let commissioner = try? HomeMatterCommissioner(appGroup: appGroup),
         let fetched = try? commissioner.fetchRooms(), !fetched.isEmpty {
        return fetched
      }
    }

    if let jsonStr = ud()?.string(forKey: "*#extRooms"),
       let data = jsonStr.data(using: .utf8),
       let list = try? JSONSerialization.jsonObject(with: data) as? [String],
       !list.isEmpty {
      return list.map { .init(displayName: $0) }
    }

    return [.init(displayName: "Living Room")]
  }

  override func configureDevice(
    named name: String,
    in room: MatterAddDeviceRequest.Room?
  ) async {
    if mode() == "google" {
      await ensureHomeConfigured()
      if let commissioner = try? HomeMatterCommissioner(appGroup: appGroup) {
        try? await commissioner.configureMatterDevice(deviceName: name, roomName: room?.displayName)
      }
    }
  }
}