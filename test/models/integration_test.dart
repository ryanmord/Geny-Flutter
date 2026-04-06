import 'package:flutter_test/flutter_test.dart';
import 'package:geny_flutter/models/integration.dart';

void main() {
  group('IntegrationsResponse', () {
    test('round-trip JSON serialization', () {
      final json = {
        'figma': {'status': 'connected'},
        'jira': {'status': 'disconnected'},
        'anthropic': {'status': 'connected'},
      };

      final response = IntegrationsResponse.fromJson(json);
      expect(response.figma.isConnected, true);
      expect(response.jira.isConnected, false);
      expect(response.anthropic.isConnected, true);

      final output = response.toJson();
      expect(response.figma.status, 'connected');
      expect(response.jira.status, 'disconnected');
      expect(output, isNotNull);
    });
  });

  group('ClaudeAuthInfo', () {
    test('round-trip JSON serialization', () {
      final json = {
        'loggedIn': true,
        'email': 'test@example.com',
        'orgName': 'Test Org',
        'subscriptionType': 'pro',
      };

      final info = ClaudeAuthInfo.fromJson(json);
      expect(info.loggedIn, true);
      expect(info.email, 'test@example.com');
      expect(info.orgName, 'Test Org');
      expect(info.subscriptionType, 'pro');
    });

    test('handles null optional fields', () {
      final json = {'loggedIn': false};

      final info = ClaudeAuthInfo.fromJson(json);
      expect(info.loggedIn, false);
      expect(info.email, isNull);
      expect(info.orgName, isNull);
    });
  });
}
