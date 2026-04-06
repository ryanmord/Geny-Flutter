import 'package:flutter_test/flutter_test.dart';
import 'package:geny_flutter/models/conversation.dart';

void main() {
  group('Conversation', () {
    test('round-trip JSON serialization', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'title': 'Test Conversation',
        'agentId': 'default',
        'sessionId': 'session-abc',
        'createdAt': '2026-04-06T12:00:00.000Z',
        'updatedAt': '2026-04-06T12:30:00.000Z',
      };

      final conversation = Conversation.fromJson(json);
      expect(conversation.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(conversation.title, 'Test Conversation');
      expect(conversation.agentId, 'default');
      expect(conversation.sessionId, 'session-abc');
      expect(conversation.createdAt, '2026-04-06T12:00:00.000Z');
      expect(conversation.updatedAt, '2026-04-06T12:30:00.000Z');

      final output = conversation.toJson();
      expect(output['id'], json['id']);
      expect(output['title'], json['title']);
      expect(output['agentId'], json['agentId']);
      expect(output['sessionId'], json['sessionId']);
    });

    test('handles null sessionId', () {
      final json = {
        'id': 'abc',
        'title': 'No Session',
        'agentId': 'default',
        'createdAt': '2026-04-06T12:00:00.000Z',
        'updatedAt': '2026-04-06T12:00:00.000Z',
      };

      final conversation = Conversation.fromJson(json);
      expect(conversation.sessionId, isNull);
    });
  });

  group('ConversationDetail', () {
    test('deserializes with messages', () {
      final json = {
        'metadata': {
          'id': 'conv-1',
          'title': 'Test',
          'agentId': 'default',
          'createdAt': '2026-04-06T12:00:00.000Z',
          'updatedAt': '2026-04-06T12:00:00.000Z',
        },
        'messages': [
          {
            'id': 'msg-1',
            'role': 'user',
            'content': [
              {'type': 'text', 'text': 'Hello'}
            ],
            'timestamp': '2026-04-06T12:00:00.000Z',
          },
          {
            'id': 'msg-2',
            'role': 'assistant',
            'content': [
              {'type': 'text', 'text': 'Hi there!'}
            ],
            'timestamp': '2026-04-06T12:00:01.000Z',
          },
        ],
      };

      final detail = ConversationDetail.fromJson(json);
      expect(detail.metadata.id, 'conv-1');
      expect(detail.messages.length, 2);
      expect(detail.messages[0].role, 'user');
      expect(detail.messages[1].role, 'assistant');
    });
  });

  group('ContentBlockJson', () {
    test('text block', () {
      final json = {'type': 'text', 'text': 'Hello world'};
      final block = ContentBlockJson.fromJson(json);
      expect(block.type, 'text');
      expect(block.text, 'Hello world');
      expect(block.language, isNull);
      expect(block.code, isNull);
      expect(block.toolName, isNull);
    });

    test('code_block', () {
      final json = {'type': 'code_block', 'language': 'dart', 'code': 'void main() {}'};
      final block = ContentBlockJson.fromJson(json);
      expect(block.type, 'code_block');
      expect(block.language, 'dart');
      expect(block.code, 'void main() {}');
    });

    test('tool_use block with result', () {
      final json = {
        'type': 'tool_use',
        'toolName': 'Read',
        'input': {'path': '/tmp/test.txt'},
        'result': {'output': 'file contents', 'error': null},
      };
      final block = ContentBlockJson.fromJson(json);
      expect(block.type, 'tool_use');
      expect(block.toolName, 'Read');
      expect(block.input, isNotNull);
      expect(block.result?.output, 'file contents');
      expect(block.result?.error, isNull);
    });
  });
}
