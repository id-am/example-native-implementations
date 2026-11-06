import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'call_state_exception.dart';
import 'call_status.dart';

/// Entrada del plugin.
///
/// En Android se requiere el permiso en tiempo de ejecución `READ_PHONE_STATE`; se
/// maneja con `permission_handler`. En iOS no se necesita permiso.
class CallState {
  CallState._();

  /// Singleton instance.
  static final CallState instance = CallState._();

  @visibleForTesting
  static const MethodChannel methodChannel = MethodChannel('call_state/methods');

  @visibleForTesting
  static const EventChannel eventChannel = EventChannel('call_state/events');

  bool get _needsPermission => !kIsWeb && Platform.isAndroid;

  /// Indica si el permiso de teléfono está actualmente concedido (siempre true en iOS).
  Future<bool> hasPermission() async {
    if (!_needsPermission) return true;
    return Permission.phone.status.isGranted;
  }

  /// Solicita el permiso de teléfono si es necesario. Devuelve `true` cuando se concede.
  Future<bool> requestPermission() async {
    if (!_needsPermission) return true;
    return (await Permission.phone.request()).isGranted;
  }

  /// Indica si el permiso fue denegado permanentemente y el usuario debe abrir
  /// la página de configuración de la app (ver [openSettings]).
  Future<bool> isPermissionPermanentlyDenied() async {
    if (!_needsPermission) return false;
    return Permission.phone.status.isPermanentlyDenied;
  }

  /// Abre la página de configuración de la app.
  Future<bool> openSettings() => openAppSettings();

  /// Devuelve `true` si el usuario está en una llamada activa.
  ///
  /// Solicita el permiso en Android cuando aún no ha sido concedido y lanza
  /// [CallStateException] con el código `permission_denied` si se rechaza.
  Future<bool> isInCall() async => (await getCallStatus()).isInCall;

  /// Devuelve el [CallStatus] actual.
  Future<CallStatus> getCallStatus() async {
    await _ensurePermission();
    try {
      final result = await methodChannel.invokeMethod<String>('getCallStatus');
      return CallStatus.fromNative(result);
    } on PlatformException catch (e) {
      throw CallStateException(e.code, e.message);
    }
  }

  /// Flujo con el estado de la llamada. Emite el estado actual al suscribirse y
  /// cada cambio posterior. El listener nativo vive mientras haya una
  /// suscripción.
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

  /// Lanza [CallStateException] si el permiso es necesario y no ha sido concedido.
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
