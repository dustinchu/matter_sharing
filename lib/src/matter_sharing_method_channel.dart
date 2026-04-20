import 'package:flutter/services.dart';
import 'matter_sharing_platform_interface.dart';
import 'matter_sharing_exception.dart';

class MethodChannelMatterSharing extends MatterSharingPlatform {
  static const _channel = MethodChannel('matter_sharing');

  @override
  Future<void> shareToAppleHome({required String onboardingPayload}) =>
      _wrap(() => _channel.invokeMethod('shareToAppleHome', {'onboardingPayload': onboardingPayload}));

  @override
  Future<void> shareToGoogleHome({
    required String onboardingPayload,
    int? discriminator,
    int? passcode,
    int? durationSeconds,
    int? vendorId,
    int? productId,
    int? deviceType,
  }) =>
      _wrap(() => _channel.invokeMethod('shareToGoogleHome', {
        'onboardingPayload': onboardingPayload,
        if (discriminator != null) 'discriminator': discriminator,
        if (passcode != null) 'passcode': passcode,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (vendorId != null) 'vendorId': vendorId,
        if (productId != null) 'productId': productId,
        if (deviceType != null) 'deviceType': deviceType,
      }));

  @override
  Future<void> configureGoogleHome(GoogleHomeConfig config) =>
      _wrap(() => _channel.invokeMethod('configureGoogleHome', config.toMap()));

  Future<void> _wrap(Future<void> Function() call) async {
    try {
      await call();
    } on PlatformException catch (e) {
      throw MatterSharingException.fromPlatformException(e);
    }
  }
}
