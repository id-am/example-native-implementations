import Flutter
import CallKit

public class CallStatePlugin: NSObject, FlutterPlugin, FlutterStreamHandler, CXCallObserverDelegate {
  private let callObserver = CXCallObserver()
  private var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = CallStatePlugin()
    let methodChannel = FlutterMethodChannel(name: "call_state/methods", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    let eventChannel = FlutterEventChannel(name: "call_state/events", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCallStatus":
      result(currentStatus())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Status

  /// Active > ringing > idle. Calls that already ended are ignored.
  private func currentStatus() -> String {
    let calls = callObserver.calls.filter { !$0.hasEnded }
    if calls.isEmpty { return "idle" }
    // Incoming call not yet answered.
    let allRinging = calls.allSatisfy { !$0.isOutgoing && !$0.hasConnected }
    return allRinging ? "ringing" : "active"
  }

  // MARK: - FlutterStreamHandler

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    callObserver.setDelegate(self, queue: DispatchQueue.main)
    events(currentStatus())
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    callObserver.setDelegate(nil, queue: nil)
    eventSink = nil
    return nil
  }

  // MARK: - CXCallObserverDelegate

  public func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
    eventSink?(currentStatus())
  }
}
