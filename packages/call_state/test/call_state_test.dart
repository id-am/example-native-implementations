import 'package:call_state/call_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CallStatus.fromNative maps values', () {
    expect(CallStatus.fromNative('active'), CallStatus.active);
    expect(CallStatus.fromNative('ringing'), CallStatus.ringing);
    expect(CallStatus.fromNative('idle'), CallStatus.idle);
    expect(CallStatus.fromNative(null), CallStatus.idle);
  });

  test('isInCall only true for active', () {
    expect(CallStatus.active.isInCall, isTrue);
    expect(CallStatus.ringing.isInCall, isFalse);
    expect(CallStatus.idle.isInCall, isFalse);
  });
}
