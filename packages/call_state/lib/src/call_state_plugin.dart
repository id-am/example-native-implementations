import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'call_state_exception.dart';
import 'call_status.dart';

/// Entry point of the plugin.
///
/// On Android the `READ_PHONE_STATE` runtime permission is required; it is
/// handled with `permission_handler`. On iOS no permission is needed.
class CallState {
  CallState._();

  /// Singleton instance.
  static final CallState instance = CallState._();

  @visibleForTesting
  static const MethodChannel methodChannel = MethodChannel('call_state/methods');

  @visibleForTesting
  static const EventChannel eventChannel = EventChannel('call_state/events');

  bool get _needsPermission => !kIsWeb && Platform.isAndroid;

  /// Whether the phone permission is currently granted (always true on iOS).
  Future<bool> hasPermission() async {
    if (!_needsPermission) return true;
    return Permission.phone.status.isGranted;
  }

  /// Requests the phone permission if needed. Returns `true` when granted.
  Future<bool> requestPermission() async {
    if (!_needsPermission) return true;
    return (await Permission.phone.request()).isGranted;
  }

  /// Whether the permission was permanently denied and the user must open
  /// the app settings (see [openSettings]).
  Future<bool> isPermissionPermanentlyDenied() async {
    if (!_needsPermission) return false;
    return Permission.phone.status.isPermanentlyDenied;
  }

  /// Opens the app settings page.
  Future<bool> openSettings() => openAppSettings();

  /// Returns `true` if the user is in an active call.
  ///
  /// Requests the permission on Android when not yet granted and throws
  /// [CallStateException] with code `permission_denied` if refused.
  Future<bool> isInCall() async => (await getCallStatus()).isInCall;

  /// Returns the current [CallStatus].
  Future<CallStatus> getCallStatus() async {
    await _ensurePermission();
    try {
      final result = await methodChannel.invokeMethod<String>('getCallStatus');
      return CallStatus.fromNative(result);
    } on PlatformException catch (e) {
      throw CallStateException(e.code, e.message);
    }
  }

  /// Stream with the call status. Emits the current status on subscribe and
  /// every later change. The native listener lives while there is a
  /// subscription.
  Stream<CallStatus> get onCallStatusChanged async* {
    await _ensurePermission();
    yield* eventChannel
        .receiveBroadcastStream()
        .map(CallStatus.fromNative)
        .handleError((Object e) {
      if (e is PlatformException) {
        throw CallStateException(e.code, e.message);
      }
      throw e;
    });
  }

  Future<void> _ensurePermission() async {
    if (await hasPermission()) return;
    if (!await requestPermission()) {
      throw const CallStateException(
        'permission_denied',
        'READ_PHONE_STATE permission was denied',
      );
    }
  }
}
