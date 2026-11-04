/// Thrown when the call state cannot be obtained.
class CallStateException implements Exception {
  const CallStateException(this.code, [this.message]);

  /// Error code, e.g. `permission_denied`.
  final String code;
  final String? message;

  @override
  String toString() => 'CallStateException($code${message != null ? ': $message' : ''})';
}
