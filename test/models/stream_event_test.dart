import 'package:flutter_test/flutter_test.dart';
import 'package:geny_flutter/models/stream_event.dart';

void main() {
  group('StreamEvent.fromJson', () {
    test('parses stream_start', () {
      final event = StreamEvent.fromJson({
        'type': 'stream_start',
        'conversationId': 'conv-1',
      });
      expect(event, isA<StreamStart>());
      expect(event.conversationId, 'conv-1');
    });

    test('parses stream_delta', () {
      final event = StreamEvent.fromJson({
        'type': 'stream_delta',
        'conversationId': 'conv-1',
        'text': 'Hello',
      });
      expect(event, isA<StreamDelta>());
      expect((event as StreamDelta).text, 'Hello');
    });

    test('parses tool_use_start', () {
      final event = StreamEvent.fromJson({
        'type': 'tool_use_start',
        'conversationId': 'conv-1',
        'toolName': 'Read',
        'toolInput': {'path': '/tmp/test.txt'},
      });
      expect(event, isA<ToolUseStart>());
      final e = event as ToolUseStart;
      expect(e.toolName, 'Read');
      expect(e.toolInput['path'], '/tmp/test.txt');
    });

    test('parses tool_result', () {
      final event = StreamEvent.fromJson({
        'type': 'tool_result',
        'conversationId': 'conv-1',
        'toolName': 'Read',
        'output': 'file content',
        'error': null,
      });
      expect(event, isA<ToolResult>());
      final e = event as ToolResult;
      expect(e.toolName, 'Read');
      expect(e.output, 'file content');
      expect(e.error, isNull);
    });

    test('parses stream_end', () {
      final event = StreamEvent.fromJson({
        'type': 'stream_end',
        'conversationId': 'conv-1',
        'costUsd': 0.05,
        'durationMs': 1234.0,
      });
      expect(event, isA<StreamEnd>());
      final e = event as StreamEnd;
      expect(e.costUsd, 0.05);
      expect(e.durationMs, 1234.0);
    });

    test('parses status_update', () {
      final event = StreamEvent.fromJson({
        'type': 'status_update',
        'conversationId': 'conv-1',
        'statusText': 'Thinking...',
      });
      expect(event, isA<StatusUpdate>());
      expect((event as StatusUpdate).statusText, 'Thinking...');
    });

    test('parses stream_error', () {
      final event = StreamEvent.fromJson({
        'type': 'stream_error',
        'conversationId': 'conv-1',
        'error': 'Something went wrong',
      });
      expect(event, isA<StreamError>());
      expect((event as StreamError).error, 'Something went wrong');
    });

    test('unknown type returns StreamError', () {
      final event = StreamEvent.fromJson({
        'type': 'unknown_type',
        'conversationId': 'conv-1',
      });
      expect(event, isA<StreamError>());
    });
  });
}
