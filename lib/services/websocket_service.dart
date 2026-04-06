import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/stream_event.dart';
import 'websocket_state.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  String? _baseUrl;

  // ---------------------------------------------------------------------------
  // Connection state
  // ---------------------------------------------------------------------------

  WebSocketState _state = WebSocketState.disconnected;
  WebSocketState get state => _state;

  final _stateController = StreamController<WebSocketState>.broadcast();
  Stream<WebSocketState> get stateStream => _stateController.stream;

  // ---------------------------------------------------------------------------
  // Event stream
  // ---------------------------------------------------------------------------

  final _eventController = StreamController<StreamEvent>.broadcast();
  Stream<StreamEvent> get eventStream => _eventController.stream;

  // ---------------------------------------------------------------------------
  // Reconnection
  // ---------------------------------------------------------------------------

  static const _maxRetries = 5;
  int _retryCount = 0;
  Timer? _reconnectTimer;
  bool _intentionalDisconnect = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  bool get isConnected => _state == WebSocketState.connected;

  void connect(String baseUrl) {
    _baseUrl = baseUrl;
    _intentionalDisconnect = false;
    _retryCount = 0;
    _connect();
  }

  void _connect() {
    if (_baseUrl == null) return;

    _setState(WebSocketState.connecting);

    final wsUrl = _baseUrl!.replaceFirst('http', 'ws');

    try {
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/ws'));
    } catch (e) {
      _setState(WebSocketState.error);
      _scheduleReconnect();
      return;
    }

    _channel!.ready.then((_) {
      _setState(WebSocketState.connected);
      _retryCount = 0;
    }).catchError((Object error) {
      _setState(WebSocketState.error);
      _scheduleReconnect();
    });

    _channel!.stream.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          final event = StreamEvent.fromJson(json);
          _eventController.add(event);
        } catch (e) {
          _eventController.addError('Failed to parse event: $e');
        }
      },
      onError: (Object error) {
        _eventController.addError(error.toString());
        _setState(WebSocketState.error);
        _scheduleReconnect();
      },
      onDone: () {
        _channel = null;
        _setState(WebSocketState.disconnected);
        if (!_intentionalDisconnect) {
          _scheduleReconnect();
        }
      },
    );
  }

  void _scheduleReconnect() {
    if (_intentionalDisconnect || _retryCount >= _maxRetries) return;

    _reconnectTimer?.cancel();
    final delaySeconds = min(pow(2, _retryCount).toInt(), 32);
    _retryCount++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), _connect);
  }

  void _setState(WebSocketState newState) {
    if (_state == newState) return;
    _state = newState;
    _stateController.add(newState);
  }

  // ---------------------------------------------------------------------------
  // Client → Server messages
  // ---------------------------------------------------------------------------

  void sendMessage({
    required String conversationId,
    required String message,
    String? agentId,
    String? workingDirectory,
  }) {
    final data = <String, dynamic>{
      'type': 'send_message',
      'conversationId': conversationId,
      'message': message,
    };
    if (agentId != null) data['agentId'] = agentId;
    if (workingDirectory != null) data['workingDirectory'] = workingDirectory;
    _send(data);
  }

  void resumeConversation({
    required String conversationId,
    required String message,
    String? workingDirectory,
  }) {
    final data = <String, dynamic>{
      'type': 'resume_conversation',
      'conversationId': conversationId,
      'message': message,
    };
    if (workingDirectory != null) data['workingDirectory'] = workingDirectory;
    _send(data);
  }

  void cancelStream(String conversationId) {
    _send({
      'type': 'cancel_stream',
      'conversationId': conversationId,
    });
  }

  void _send(Map<String, dynamic> data) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(data));
  }

  // ---------------------------------------------------------------------------
  // Teardown
  // ---------------------------------------------------------------------------

  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setState(WebSocketState.disconnected);
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _eventController.close();
  }
}
