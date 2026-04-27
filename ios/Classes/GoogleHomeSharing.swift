import Flutter
import MatterSupport
import Matter

// GoogleHomeSDK is provided by the host app via SPM - imported conditionally
#if canImport(GoogleHomeSDK)
import GoogleHomeSDK
#endif

@available(iOS 16.1, *)
class GoogleHomeSharing {

  static let shared = GoogleHomeSharing()

  private var teamID: String = ""
  private var clientID: String = ""
  private var serverClientID: String = ""
  private var appGroup: String = ""
  private var isConfigured = false

  #if canImport(GoogleHomeSDK)
  private var cachedHome: Home?
  private var activeStructure: Structure?
  #endif

  private init() {}

  func configure(teamID: String, clientID: String, serverClientID: String, appGroup: String) {
    self.teamID = teamID
    self.clientID = clientID
    self.serverClientID = serverClientID
    self.appGroup = appGroup
    self.isConfigured = true

    #if canImport(GoogleHomeSDK)
    Task { @MainActor in
      Home.configure {
        $0.teamID = teamID
        $0.clientID = clientID
        $0.serverClientID = serverClientID
        $0.sharedAppGroup = appGroup
      }
      NSLog("[GoogleHomeSharing] Home.configure() done")
    }
    #else
    NSLog("[GoogleHomeSharing] GoogleHomeSDK not linked - configure() is a no-op")
    #endif
  }

  @MainActor
  func share(onboardingPayload: String, result: @escaping FlutterResult) {
    #if canImport(GoogleHomeSDK)
    guard isConfigured else {
      result(FlutterError(
        code: "NOT_CONFIGURED",
        message: "Google Home is not configured. In your iOS Info.plist, set MatterSharingEnabled=true and provide MatterSharingTeamID, MatterSharingClientID, MatterSharingServerClientID, MatterSharingAppGroup.",
        details: nil
      ))
      return
    }

    Task {
      do {
        // Reuse session or sign in
        if cachedHome == nil {
          cachedHome = await Home.restoreSession()
        }
        if cachedHome == nil {
          NSLog("[GoogleHomeSharing] No session, calling Home.connect()")
          cachedHome = try await Home.connect()
        } else {
          NSLog("[GoogleHomeSharing] Reusing existing Home session")
        }
        let home = cachedHome!

        var structures = try await home.structures().list()
        NSLog("[GoogleHomeSharing] structures count: %d", structures.count)

        if structures.isEmpty {
          NSLog("[GoogleHomeSharing] No structures, presenting permissions update")
          await home.permissions.presentPermissionsUpdate()
          structures = try await home.structures().list()
        }

        guard let structure = structures.first else {
          result(FlutterError(
            code: "NO_STRUCTURE",
            message: """
            No Google Home structure found. Possible causes:
            1. You have no home set up in the Google Home app (e.g. no Google Home Mini or other device added yet).
            2. You are signed in with a Google account that has no home, or the home was created under a different account.
            3. You are not the home owner - only the account that created the home has full control. Ask the owner to share access or sign in with the owner account.
            4. Home access permission was denied when requested.

            To fix: open the Google Home app, confirm a home exists, and make sure you are signed in as the home owner.
            """,
            details: nil
          ))
          return
        }
        NSLog("[GoogleHomeSharing] Using structure: %@", structure.name)

        // Clean up any previous uncommitted session
        if let prev = activeStructure {
          NSLog("[GoogleHomeSharing] Cleaning up previous commissioning session")
          _ = prev.markMatterCommissioningFailed(error: NSError(domain: "GH", code: -1))
          activeStructure = nil
        }

        try await structure.prepareForMatterCommissioning()
        activeStructure = structure
        NSLog("[GoogleHomeSharing] prepareForMatterCommissioning done")

        let topology = MatterAddDeviceRequest.Topology(
          ecosystemName: "Google Home",
          homes: []
        )
        var request = MatterAddDeviceRequest(topology: topology)
        if let mtrPayload = parseMatterPayload(onboardingPayload) {
          request.setupPayload = mtrPayload
          NSLog("[GoogleHomeSharing] setupPayload set from: %@", onboardingPayload)
        } else {
          NSLog("[GoogleHomeSharing] setupPayload parse failed, user must scan QR manually")
        }

        // Signal extension to use Google Home commissioning
        if !appGroup.isEmpty, let ud = UserDefaults(suiteName: appGroup) {
          ud.set("google", forKey: "*#extCommissioningMode")
          ud.synchronize()
        }

        NSLog("[GoogleHomeSharing] Starting MatterAddDeviceRequest.perform()")
        do {
          try await request.perform()
          NSLog("[GoogleHomeSharing] perform() done")
          let deviceIDs = try await structure.completeMatterCommissioning()
          activeStructure = nil
          NSLog("[GoogleHomeSharing] Commissioned: %@", deviceIDs.joined(separator: ", "))
          result(nil)
        } catch {
          _ = structure.markMatterCommissioningFailed(error: error)
          activeStructure = nil
          let nsErr = error as NSError
          // HFErrorDomain Code=33: device already associated to this home
          // MatterSupport error 1 wrapping HFErrorDomain 33: same duplicate case
          let isDuplicate = (nsErr.domain == "HFErrorDomain" && nsErr.code == 33)
            || (nsErr.userInfo[NSUnderlyingErrorKey] as? NSError).map {
                $0.domain == "HFErrorDomain" && $0.code == 33
               } ?? false
          if isDuplicate {
            result(FlutterError(
              code: "ALREADY_COMMISSIONED",
              message: "This device has already been added to Google Home. Please remove it from the Google Home app first before adding again.",
              details: ["domain": nsErr.domain, "code": nsErr.code]
            ))
          } else if Self.isUserCancelled(error) {
            NSLog("[GoogleHomeSharing] User cancelled commissioning UI")
            result(FlutterError(
              code: "CANCELLED",
              message: "User cancelled Google Home commissioning.",
              details: nil
            ))
          } else {
            result(FlutterError(
              code: "COMMISSION_FAILED",
              message: """
              Commissioning failed: \(error.localizedDescription)

              Possible causes:
              1. You are not the Google Home owner - only the home owner can add new devices.
              2. The device has reached the maximum number of fabrics and cannot join another home.
              3. A Bluetooth or network issue interrupted commissioning - move closer to the device and try again.
              4. The Google Home in the app belongs to a different Google account than the one signed in.
              """,
              details: [
                "domain": nsErr.domain,
                "code": nsErr.code,
                "underlyingError": nsErr.userInfo[NSUnderlyingErrorKey].map { "\($0)" } ?? "none"
              ]
            ))
          }
        }

      } catch {
        activeStructure?.markMatterCommissioningFailed(error: error)
        activeStructure = nil
        if Self.isUserCancelled(error) {
          NSLog("[GoogleHomeSharing] User cancelled (outer)")
          result(FlutterError(
            code: "CANCELLED",
            message: "User cancelled Google Home commissioning.",
            details: nil
          ))
          return
        }
        cachedHome = nil
        NSLog("[GoogleHomeSharing] Error: %@", error.localizedDescription)
        result(FlutterError(
          code: "ERROR",
          message: error.localizedDescription,
          details: [
            "domain": (error as NSError).domain,
            "code": (error as NSError).code
          ]
        ))
      }
    }
    #else
    result(FlutterError(
      code: "SDK_NOT_LINKED",
      message: "GoogleHomeSDK not available.",
      details: nil
    ))
    #endif
  }

  #if canImport(GoogleHomeSDK)
  private func parseMatterPayload(_ payload: String) -> MTRSetupPayload? {
    return MatterCommissioningUtils.matterSetupPayload(from: payload)
  }
  #endif

  /// Detects whether an error represents a user-initiated cancellation of the
  /// system commissioning UI. Walks the underlying error chain because
  /// MatterSupport and GoogleHomeSDK frequently wrap the original cancel error.
  ///
  /// IMPORTANT: `com.apple.MatterSupport` domain `code == 1` is NOT a reliable
  /// cancel signal. iOS reports the same code for fabric conflicts, fail-safe
  /// timer expiry, and extension failures. A real user cancel always has a
  /// concrete underlying NSCocoa/HMError cancel in the chain.
  static func isUserCancelled(_ error: Error) -> Bool {
    var current: NSError? = error as NSError
    while let err = current {
      if err.domain == NSCocoaErrorDomain && err.code == NSUserCancelledError {
        return true
      }
      if err.domain == "HMErrorDomain" && err.code == 38 {
        return true
      }
      if err.domain == NSPOSIXErrorDomain && err.code == 89 {
        return true
      }
      current = err.userInfo[NSUnderlyingErrorKey] as? NSError
    }
    return false
  }
}
