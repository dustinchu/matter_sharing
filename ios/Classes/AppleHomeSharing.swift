import Flutter
import MatterSupport
import Matter
import HomeKit

@available(iOS 16.1, *)
class AppleHomeSharing {

  static func share(onboardingPayload: String, result: @escaping FlutterResult) {
    NSLog("[AppleHomeSharing] share called, payload: %@", onboardingPayload)

    var mtrPayload: MTRSetupPayload?
    if onboardingPayload.hasPrefix("MT:") {
      let parser = MTRQRCodeSetupPayloadParser(base38Representation: onboardingPayload)
      mtrPayload = try? parser.populatePayload()
    } else {
      let parser = MTRManualSetupPayloadParser(decimalStringRepresentation: onboardingPayload)
      mtrPayload = try? parser.populatePayload()
    }

    guard let mtrPayload = mtrPayload else {
      NSLog("[AppleHomeSharing] Failed to parse payload")
      result(FlutterError(
        code: "INVALID_PAYLOAD",
        message: "Failed to parse onboarding payload",
        details: nil
      ))
      return
    }

    let request = HMAccessorySetupRequest()
    request.matterPayload = mtrPayload

    let manager = HMAccessorySetupManager()
    Task {
      do {
        let setupResult = try await manager.performAccessorySetup(using: request)
        NSLog("[AppleHomeSharing] Success, home: %@", setupResult.homeUniqueIdentifier.uuidString)
        result(nil)
      } catch {
        NSLog("[AppleHomeSharing] Failed: %@", String(describing: error))
        if GoogleHomeSharing.isUserCancelled(error) {
          result(FlutterError(
            code: "CANCELLED",
            message: "User cancelled Apple Home sharing.",
            details: nil
          ))
          return
        }
        result(FlutterError(
          code: "SHARE_FAILED",
          message: error.localizedDescription,
          details: [
            "domain": (error as NSError).domain,
            "code": (error as NSError).code
          ]
        ))
      }
    }
  }
}
