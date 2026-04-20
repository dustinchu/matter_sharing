import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'models/sharing_config.dart';

export 'models/sharing_config.dart';

abstract class MatterSharingPlatform extends PlatformInterface {
  MatterSharingPlatform() : super(token: _token);

  static final Object _token = Object();

  static MatterSharingPlatform _instance = _DefaultMatterSharingPlatform();

  static MatterSharingPlatform get instance => _instance;

  static set instance(MatterSharingPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> shareToAppleHome({required String onboardingPayload}) {
    throw UnimplementedError('shareToAppleHome() not implemented.');
  }

  Future<void> shareToGoogleHome({
    required String onboardingPayload,
    int? discriminator,
    int? passcode,
    int? durationSeconds,
    int? vendorId,
    int? productId,
    int? deviceType,
  }) {
    throw UnimplementedError('shareToGoogleHome() not implemented.');
  }

  Future<void> configureGoogleHome(GoogleHomeConfig config) {
    throw UnimplementedError('configureGoogleHome() not implemented.');
  }
}

class _DefaultMatterSharingPlatform extends MatterSharingPlatform {}
