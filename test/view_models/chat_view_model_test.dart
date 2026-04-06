import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geny_flutter/models/message.dart';
import 'package:geny_flutter/models/stream_event.dart';
import 'package:geny_flutter/services/backend_service.dart';
import 'package:geny_flutter/services/websocket_service.dart';
import 'package:geny_flutter/view_models/chat_view_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

/// A thin wrapper that exposes the WebSocketService event stream controller
/// so tests can inject events without a real WebSocket connection.
class TestWebSocketService extends WebSocketService {
  final StreamController<StreamEvent> testEventController =
      StreamController<StreamEvent>.broadcast();

  @override
  Stream<StreamEvent> get eventStream => testEventController.stream;

  final List<Map<String, dynamic>> sentMessages = [];

  @override
  void sendMessage({
    required String conversationId,
    required String message,
    String? agentId,
    String? workingDirectory,
  }) {
    sentMessages.add({
      'type': 'send_message',
      'conversationId': conversationId,
      'message': message,
      if (agentId != null) 'agentId': agentId,
      if (workingDirectory != null) 'workingDirectory': workingDirectory,
    });
  }

  @override
  void cancelStream(String conversationId) {
    sentMessages.add({
      'type': 'cancel_stream',
      'conversationId': conversationId,
    });
  }

  @override
  void dispose() {
    testEventController.close();
    super.dispose();
  }
}

BackendService _buildBackendService(
    http.Response Function(http.Request) handler) {
  return BackendService(
    baseUrl: 'http://localhost:3000',
    client: http_testing.MockClient(
        (req) async => handler(req)),
  );
}

void main() {
  late TestWebSocketService wsService;
  late BackendService backendService;
  late ChatViewModel viewModel;

  setUp(() {
    wsService = TestWebSocketService();
    backendService = _buildBackendService((_) => http.Response('{}', 200));
    viewModel = ChatViewModel(
      backendService: backendService,
      webSocketService: wsService,
    );
  });

  tearDown(() {
    viewModel.dispose();
    wsService.dispose();
    backendService.dispose();
  });

  group('ChatViewModel initial state', () {
    test('starts with empty messages and no streaming', () {
      expect(viewModel.messages, isEmpty);
      expect(viewModel.isStreaming, false);
      expect(viewModel.streamingText, '');
      expect(viewModel.currentToolUse, isNull);
      expect(viewModel.statusText, isNull);
      expect(viewModel.error, isNull);
      expect(viewModel.currentConversationId, isNull);
    });
  });

  group('loadConversation', () {
    test('loads messages from backend', () async {
      final detail = {
        'metadata': {
          'id': 'conv-1',
          'title': 'Test',
          'agentId': 'agent-1',
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
        },
        'messages': [
          {
            'id': 'msg-1',
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Hello'}
            ],
            'timestamp': '2024-01-01T00:00:00Z',
          },
          {
            'id': 'msg-2',
            'role': 'assistant',
            'content': [
              {'type': 'text', 'text': 'Hi there'}
            ],
            'timestamp': '2024-01-01T00:00:01Z',
          },
        ],
      };

      backendService.dispose();
      backendService = _buildBackendService((req) {
        if (req.url.path.contains('/api/conversations/conv-1')) {
          return http.Response(jsonEncode(detail), 200);
        }
        return http.Response('Not found', 404);
      });

      viewModel.dispose();
      viewModel = ChatViewModel(
        backendService: backendService,
        webSocketService: wsService,
      );

      await viewModel.loadConversation('conv-1');

      expect(viewModel.currentConversationId, 'conv-1');
      expect(viewModel.messages.length, 2);
      expect(viewModel.messages[0].role, MessageRole.user);
      expect(viewModel.messages[1].role, MessageRole.assistant);
    });

    test('clears state on error', () async {
      backendService.dispose();
      backendService = _buildBackendService(
          (_) => http.Response('{"error": "Not found"}', 404));

      viewModel.dispose();
      viewModel = ChatViewModel(
        backendService: backendService,
        webSocketService: wsService,
      );

      await viewModel.loadConversation('bad-id');

      expect(viewModel.error, isNotNull);
      expect(viewModel.messages, isEmpty);
    });
  });

  group('sendMessage', () {
    test('adds user message and sends via WebSocket', () {
      viewModel.loadConversation('conv-1').ignore();
      // Set the conversation id synchronously for testing
      // loadConversation sets it immediately before the async call
      expect(viewModel.currentConversationId, 'conv-1');

      viewModel.sendMessage('Hello world');

      expect(viewModel.messages.length, 1);
      expect(viewModel.messages.last.role, MessageRole.user);
      expect(
        (viewModel.messages.last.content.first as TextBlock).text,
        'Hello world',
      );
      expect(wsService.sentMessages.length, 1);
      expect(wsService.sentMessages.first['message'], 'Hello world');
    });

    test('does nothing without a current conversation', () {
      viewModel.sendMessage('Hello');
      expect(viewModel.messages, isEmpty);
      expect(wsService.sentMessages, isEmpty);
    });

    test('does nothing with blank text', () {
      viewModel.loadConversation('conv-1').ignore();
      viewModel.sendMessage('   ');
      expect(viewModel.messages, isEmpty);
    });
  });

  group('stream event processing', () {
    setUp(() {
      viewModel.loadConversation('conv-1').ignore();
    });

    test('stream_start sets isStreaming', () {
      wsService.testEventController
          .add(const StreamStart(conversationId: 'conv-1'));

      // Events are processed async via stream listener
      return Future.microtask(() {
        expect(viewModel.isStreaming, true);
        expect(viewModel.error, isNull);
      });
    });

    test('stream_delta accumulates text', () async {
      wsService.testEventController
          .add(const StreamStart(conversationId: 'conv-1'));
      await Future.microtask(() {});

      wsService.testEventController
          .add(const StreamDelta(conversationId: 'conv-1', text: 'Hello'));
      await Future.microtask(() {});
      expect(viewModel.streamingText, 'Hello');

      wsService.testEventController
          .add(const StreamDelta(conversationId: 'conv-1', text: ' World'));
      await Future.microtask(() {});
      expect(viewModel.streamingText, 'Hello World');
    });

    test('tool_use_start creates tool block in assistant message', () async {
      wsService.testEventController
          .add(const StreamStart(conversationId: 'conv-1'));
      await Future.microtask(() {});

      wsService.testEventController.add(const ToolUseStart(
        conversationId: 'conv-1',
        toolName: 'Read',
        toolInput: {'path': '/test.txt'},
      ));
      await Future.microtask(() {});

      expect(viewModel.currentToolUse, isNotNull);
      expect(viewModel.currentToolUse!.name, 'Read');
      // An assistant message should have been created
      expect(viewModel.messages.isNotEmpty, true);
      expect(viewModel.messages.last.role, MessageRole.assistant);
    });

    test('tool_result updates current tool and collapses it', () async {
      wsService.testEventController
          .add(const StreamStart(conversationId: 'conv-1'));
      await Future.microtask(() {});

      wsService.testEventController.add(const ToolUseStart(
        conversationId: 'conv-1',
        toolName: 'Read',
        toolInput: {},
      ));
      await Future.microtask(() {});

      wsService.testEventController.add(const ToolResult(
        conversationId: 'conv-1',
        toolName: 'Read',
        output: 'file content',
      ));
      await Future.microtask(() {});

      expect(viewModel.currentToolUse, isNull);
      // Find the tool block in the assistant message
      final assistantMsg = viewModel.messages.last;
      final toolBlock =
          assistantMsg.content.whereType<ToolUseBlock>().first;
      expect(toolBlock.result, isNotNull);
      expect(toolBlock.result!.output, 'file content');
      expect(toolBlock.isCollapsed, true);
    });

    test('stream_end finalizes streaming', () async {
      wsService.testEventController
          .add(const StreamStart(conversationId: 'conv-1'));
      await Future.microtask(() {});

      wsService.testEventController
          .add(const StreamDelta(conversationId: 'conv-1', text: 'Done'));
      await Future.microtask(() {});

      wsService.testEventController.add(const StreamEnd(
        conversationId: 'conv-1',
        costUsd: 0.05,
        durationMs: 1234,
      ));
      await Future.microtask(() {});

      expect(viewModel.isStreaming, false);
      expect(viewModel.lastCostUsd, 0.05);
      expect(viewModel.lastDurationMs, 1234);
      // Streaming text should have been finalized into a message
      expect(viewModel.streamingText, '');
    });

    test('status_update sets statusText', () async {
      wsService.testEventController.add(
          const StatusUpdate(conversationId: 'conv-1', statusText: 'Thinking...'));
      await Future.microtask(() {});

      expect(viewModel.statusText, 'Thinking...');
    });

    test('stream_error sets error and stops streaming', () async {
      wsService.testEventController
          .add(const StreamStart(conversationId: 'conv-1'));
      await Future.microtask(() {});

      wsService.testEventController.add(
          const StreamError(conversationId: 'conv-1', error: 'Rate limited'));
      await Future.microtask(() {});

      expect(viewModel.isStreaming, false);
      expect(viewModel.error, 'Rate limited');
    });

    test('events for non-active conversations are ignored', () async {
      wsService.testEventController
          .add(const StreamStart(conversationId: 'other-conv'));
      await Future.microtask(() {});

      expect(viewModel.isStreaming, false);
    });
  });

  group('cancelStream', () {
    test('sends cancel via WebSocket', () {
      viewModel.loadConversation('conv-1').ignore();

      wsService.testEventController
          .add(const StreamStart(conversationId: 'conv-1'));
      return Future.microtask(() {
        viewModel.cancelStream();
        expect(wsService.sentMessages.length, 1);
        expect(wsService.sentMessages.first['type'], 'cancel_stream');
      });
    });
  });

  group('clearConversation', () {
    test('resets all state', () {
      viewModel.loadConversation('conv-1').ignore();
      viewModel.sendMessage('hello');
      viewModel.clearConversation();

      expect(viewModel.messages, isEmpty);
      expect(viewModel.currentConversationId, isNull);
      expect(viewModel.isStreaming, false);
      expect(viewModel.error, isNull);
    });
  });
}
