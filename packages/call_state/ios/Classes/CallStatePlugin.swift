import Flutter
import CallKit

/// Implementa en iOS los canales de Flutter para consultar y observar el estado de llamadas.
///
/// Usa `CXCallObserver` para obtener las llamadas activas y publicar sus cambios.
public class CallStatePlugin: NSObject, FlutterPlugin, FlutterStreamHandler, CXCallObserverDelegate {
  private let callObserver = CXCallObserver()
  private var eventSink: FlutterEventSink?

  /// Crea el plugin y registra sus canales de métodos y eventos en Flutter.
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = CallStatePlugin()
    let methodChannel = FlutterMethodChannel(name: "call_state/methods", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    let eventChannel = FlutterEventChannel(name: "call_state/events", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance)
  }

  /// Responde a los métodos del canal; `getCallStatus` devuelve el estado actual.
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCallStatus":
      result(currentStatus())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // Status

  /// Calcula el estado actual: `active`, `ringing` o `idle`.
  ///
  /// Ignora llamadas finalizadas. Si todas las llamadas restantes son entrantes
  /// y aún no están conectadas, devuelve `ringing`; en los demás casos devuelve `active`.
  private func currentStatus() -> String {
    let calls = callObserver.calls.filter { !$0.hasEnded }
    if calls.isEmpty { return "idle" }
    // Incoming call not yet answered.
    let allRinging = calls.allSatisfy { !$0.isOutgoing && !$0.hasConnected }
    return allRinging ? "ringing" : "active"
  }

  // FlutterStreamHandler

  /// Guarda el receptor de eventos, comienza a observar llamadas y envía el estado inicial.
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    callObserver.setDelegate(self, queue: DispatchQueue.main)
    events(currentStatus())
    return nil
  }

  /// Deja de observar llamadas y libera el receptor de eventos al cancelar la suscripción.
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    callObserver.setDelegate(nil, queue: nil)
    eventSink = nil
    return nil
  }

  // CXCallObserverDelegate

  /// Publica el estado actualizado cuando CallKit notifica un cambio en una llamada.
  public func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
    eventSink?(currentStatus())
  }
}
