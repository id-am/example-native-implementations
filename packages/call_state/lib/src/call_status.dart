/// Status of the phone call as reported by the native platform.
enum CallStatus {
  /// No call in progress.
  idle,

  /// An incoming call is ringing.
  ringing,

  /// A call is active (connected, dialing or on hold).
  active;

  /// `true` when the user is in an ongoing call (not merely ringing).
  bool get isInCall => this == CallStatus.active;

  /// Parses the value sent by the native side. Unknown values map to [idle].
  static CallStatus fromNative(Object? value) {
    switch (value) {
      case 'ringing':
        return CallStatus.ringing;
      case 'active':
        return CallStatus.active;
      default:
        return CallStatus.idle;
    }
  }
}
