import 'package:flutter_test/flutter_test.dart';
import 'package:geny_flutter/models/agent.dart';

void main() {
  group('Agent', () {
    test('round-trip JSON serialization', () {
      final json = {
        'id': 'ios-developer',
        'name': 'iOS Developer',
        'description': 'Specialized in iOS development',
        'model': 'claude-3-5-sonnet-20241022',
        'color': '#007AFF',
      };

      final agent = Agent.fromJson(json);
      expect(agent.id, 'ios-developer');
      expect(agent.name, 'iOS Developer');
      expect(agent.description, 'Specialized in iOS development');
      expect(agent.model, 'claude-3-5-sonnet-20241022');
      expect(agent.color, '#007AFF');

      final output = agent.toJson();
      expect(output, json);
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'default',
        'name': 'Default',
        'description': 'Default agent',
      };

      final agent = Agent.fromJson(json);
      expect(agent.model, isNull);
      expect(agent.color, isNull);
    });

    test('equality based on id', () {
      final a = Agent(id: 'test', name: 'A', description: 'a');
      final b = Agent(id: 'test', name: 'B', description: 'b');
      expect(a, equals(b));
    });
  });
}
