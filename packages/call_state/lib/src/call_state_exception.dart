/// Lanza cuando no se puede obtener el estado de la llamada.
/// Contiene un código de error y un mensaje opcional.
class CallStateException implements Exception {
  const CallStateException(this.code, [this.message]);

  /// Código de error, por ejemplo `permission_denied`.
  final String code;
  /// Mensaje opcional con información adicional sobre el error.
  final String? message;

  @override
  String toString() => 'CallStateException($code${message != null ? ': $message' : ''})';
}
