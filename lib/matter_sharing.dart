import 'src/matter_sharing_platform_interface.dart';
import 'src/matter_sharing_method_channel.dart';

export 'src/matter_sharing_platform_interface.dart' show GoogleHomeConfig;
export 'src/matter_sharing_exception.dart'
    show MatterSharingException, MatterSharingErrorCode;

class MatterSharing {
  static final MatterSharingPlatform _platform = _createPlatform();

  static MatterSharingPlatform _createPlatform() {
    final impl = MethodChannelMatterSharing();
    MatterSharingPlatform.instance = impl;
    return impl;
  }

  /// iOS: Share to Apple Home.
  /// Requires matter.allow-setup-payload entitlement.
  static Future<void> shareToAppleHome({required String onboardingPayload}) =>
      _platform.shareToAppleHome(onboardingPayload: onboardingPayload);

  /// iOS + Android: Share to Google Home.
  /// Requires Google Home SDK configured and Matter extension (iOS).
  static Future<void> shareToGoogleHome({
    required String onboardingPayload,
    int? discriminator,
    int? passcode,
    int? durationSeconds,
    int? vendorId,
    int? productId,
    int? deviceType,
  }) =>
      _platform.shareToGoogleHome(
        onboardingPayload: onboardingPayload,
        discriminator: discriminator,
        passcode: passcode,
        durationSeconds: durationSeconds,
        vendorId: vendorId,
        productId: productId,
        deviceType: deviceType,
      );

  /// iOS only: Configure Google Home SDK.
  /// Must be called before shareToGoogleHome, typically at app startup.
  static Future<void> configureGoogleHome(GoogleHomeConfig config) =>
      _platform.configureGoogleHome(config);
}
