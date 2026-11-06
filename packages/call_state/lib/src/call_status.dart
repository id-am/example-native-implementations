/// Estado de la llamada según lo reportado por la plataforma nativa.
enum CallStatus {
  /// No hay llamada en curso.
  idle,

  /// Una llamada entrante está sonando.
  ringing,

  /// Una llamada está activa (conectada, marcando o en espera).
  active;

  /// `true` cuando el usuario está en una llamada en curso (no solo sonando).
  bool get isInCall => this == CallStatus.active;

  /// Parsea el valor enviado por la plataforma nativa. Valores desconocidos se mapean a [idle].
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
