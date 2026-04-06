import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/stream_event.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  void Function(StreamEvent)? onEvent;
  void Function()? onDisconnect;
  void Function(String)? onError;

  bool get isConnected => _channel != null;

  void connect(String baseUrl) {
    final wsUrl = baseUrl.replaceFirst('http', 'ws');
    _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/ws'));

    _channel!.stream.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          final event = StreamEvent.fromJson(json);
          onEvent?.call(event);
        } catch (e) {
          onError?.call('Failed to parse event: $e');
        }
      },
      onError: (error) {
        onError?.call(error.toString());
      },
      onDone: () {
        _channel = null;
        onDisconnect?.call();
      },
    );
  }

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
    if (_channel == null) {
      onError?.call('WebSocket not connected');
      return;
    }
    _channel!.sink.add(jsonEncode(data));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
  }
}
