import 'package:flutter_test/flutter_test.dart';
import 'package:geny_flutter/services/websocket_service.dart';
import 'package:geny_flutter/services/websocket_state.dart';

void main() {
  group('WebSocketService', () {
    late WebSocketService service;

    setUp(() {
      service = WebSocketService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is disconnected', () {
      expect(service.state, WebSocketState.disconnected);
      expect(service.isConnected, false);
    });

    test('eventStream is a broadcast stream', () {
      // Should allow multiple listeners without error
      service.eventStream.listen((_) {});
      service.eventStream.listen((_) {});
    });

    test('stateStream is a broadcast stream', () {
      service.stateStream.listen((_) {});
      service.stateStream.listen((_) {});
    });

    test('disconnect sets state to disconnected', () {
      service.disconnect();
      expect(service.state, WebSocketState.disconnected);
    });

    test('disconnect is idempotent', () {
      service.disconnect();
      service.disconnect();
      expect(service.state, WebSocketState.disconnected);
    });
  });
}
