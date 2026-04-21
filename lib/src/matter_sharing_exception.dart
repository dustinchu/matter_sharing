import 'package:flutter/services.dart';

enum MatterSharingErrorCode {
  /// Could not parse the onboarding payload string (iOS only).
  invalidPayload,

  /// Google Home SDK not configured before calling shareToGoogleHome.
  notConfigured,

  /// No Google Home structure found.
  ///
  /// Possible causes:
  /// - User has no home created in Google Home app (e.g. no Google Home Mini or other device set up).
  /// - The signed-in Google account has no Google Home structure (home was created under a different account).
  /// - The signed-in account is not the home owner - only the owner has full structure access.
  /// - Permissions were denied when the SDK asked for home access.
  ///
  /// Ask the user to open Google Home app, confirm a home exists, and ensure
  /// they are signed in with the owner account before retrying.
  noStructure,

  /// Commissioning failed.
  ///
  /// Possible causes:
  /// - User is not the Google Home owner (guests/members cannot commission devices).
  /// - Device has already been commissioned to the maximum number of fabrics.
  /// - Bluetooth or network connectivity issue during commissioning.
  /// - The Google Home app home is owned by a different Google account.
  commissionFailed,

  /// Device has already been added to this Google Home.
  ///
  /// The device is already commissioned to the same home. Remove it from
  /// the Google Home app first before adding it again.
  alreadyCommissioned,

  /// General error (sign-in cancelled, network error, etc).
  error,

  /// GoogleHomeSDK not linked into the host app (iOS only).
  sdkNotLinked,

  /// Apple Home sharing failed (iOS only).
  appleHomeFailed,

  /// Requires iOS 16.1+ (iOS only).
  unsupported,

  /// Invalid or missing arguments passed to the platform method.
  invalidArgs,

  /// User cancelled the commissioning UI (Android only).
  cancelled,

  /// Google Play Services error (Android only).
  googleHomeError,

  /// Unknown error code returned from platform.
  unknown,
}

class MatterSharingException implements Exception {
  final MatterSharingErrorCode code;
  final String message;

  /// Raw platform error details (domain, native code, underlyingError).
  final Map<String, dynamic>? details;

  const MatterSharingException({
    required this.code,
    required this.message,
    this.details,
  });

  static MatterSharingException fromPlatformException(PlatformException e) {
    final details =
        e.details is Map ? Map<String, dynamic>.from(e.details as Map) : null;

    final code = switch (e.code) {
      'INVALID_PAYLOAD' => MatterSharingErrorCode.invalidPayload,
      'NOT_CONFIGURED' => MatterSharingErrorCode.notConfigured,
      'NO_STRUCTURE' => MatterSharingErrorCode.noStructure,
      'COMMISSION_FAILED' => MatterSharingErrorCode.commissionFailed,
      'ALREADY_COMMISSIONED' => MatterSharingErrorCode.alreadyCommissioned,
      'ERROR' => MatterSharingErrorCode.error,
      'SDK_NOT_LINKED' => MatterSharingErrorCode.sdkNotLinked,
      'APPLE_HOME_FAILED' => MatterSharingErrorCode.appleHomeFailed,
      'SHARE_FAILED' => MatterSharingErrorCode.appleHomeFailed,
      'UNSUPPORTED' => MatterSharingErrorCode.unsupported,
      'INVALID_ARGS' => MatterSharingErrorCode.invalidArgs,
      'CANCELLED' => MatterSharingErrorCode.cancelled,
      'GOOGLE_HOME_ERROR' => MatterSharingErrorCode.googleHomeError,
      _ => MatterSharingErrorCode.unknown,
    };

    return MatterSharingException(
      code: code,
      message: e.message ?? e.code,
      details: details,
    );
  }

  @override
  String toString() => 'MatterSharingException($code): $message';
}
