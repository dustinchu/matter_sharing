import Flutter
import UIKit

@objc(MatterSharingPlugin)
public class MatterSharingPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "matter_sharing", binaryMessenger: registrar.messenger())
    let instance = MatterSharingPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  /// Call this in AppDelegate.application(_:didFinishLaunchingWithOptions:).
  /// Reads Google Home credentials from Info.plist keys:
  ///   MatterSharingEnabled        - Bool, set to true to enable Google Home
  ///   MatterSharingTeamID         - String, Apple Developer Team ID
  ///   MatterSharingClientID       - String, Google OAuth2 iOS client ID
  ///   MatterSharingServerClientID - String, Google OAuth2 server client ID
  ///   MatterSharingAppGroup       - String, iOS App Group identifier
  @objc public static func configureGoogleHomeFromPlist() {
    guard let plist = Bundle.main.infoDictionary,
          let enabled = plist["MatterSharingEnabled"] as? Bool, enabled,
          let teamID = plist["MatterSharingTeamID"] as? String,
          let clientID = plist["MatterSharingClientID"] as? String,
          let serverClientID = plist["MatterSharingServerClientID"] as? String,
          let appGroup = plist["MatterSharingAppGroup"] as? String else {
      NSLog("[MatterSharingPlugin] Google Home not configured (MatterSharingEnabled missing or false)")
      return
    }
    guard #available(iOS 16.1, *) else { return }
    GoogleHomeSharing.shared.configure(
      teamID: teamID,
      clientID: clientID,
      serverClientID: serverClientID,
      appGroup: appGroup
    )
    NSLog("[MatterSharingPlugin] Google Home configured from Info.plist")
  }

  /// Legacy method kept for backwards compatibility.
  @objc public static func configureGoogleHome(
    teamID: String,
    clientID: String,
    serverClientID: String,
    appGroup: String
  ) {
    guard #available(iOS 16.1, *) else { return }
    GoogleHomeSharing.shared.configure(
      teamID: teamID,
      clientID: clientID,
      serverClientID: serverClientID,
      appGroup: appGroup
    )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(FlutterError(code: "UNSUPPORTED", message: "Requires iOS 16.1+", details: nil))
      return
    }
    switch call.method {
    case "shareToAppleHome":
      guard let args = call.arguments as? [String: Any],
            let payload = args["onboardingPayload"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "onboardingPayload required", details: nil))
        return
      }
      AppleHomeSharing.share(onboardingPayload: payload, result: result)

    case "shareToGoogleHome":
      guard let args = call.arguments as? [String: Any],
            let payload = args["onboardingPayload"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "onboardingPayload required", details: nil))
        return
      }
      Task { @MainActor in
        GoogleHomeSharing.shared.share(onboardingPayload: payload, result: result)
      }

    case "configureGoogleHome":
      guard let args = call.arguments as? [String: Any],
            let teamID = args["teamID"] as? String,
            let clientID = args["clientID"] as? String,
            let serverClientID = args["serverClientID"] as? String,
            let appGroup = args["appGroup"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "teamID, clientID, serverClientID, appGroup required", details: nil))
        return
      }
      DispatchQueue.main.async {
        GoogleHomeSharing.shared.configure(
          teamID: teamID,
          clientID: clientID,
          serverClientID: serverClientID,
          appGroup: appGroup
        )
        result(nil)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
