import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/agent.dart';
import '../models/conversation.dart';
import '../models/integration.dart';

class BackendServiceException implements Exception {
  final String message;
  final int? statusCode;

  const BackendServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'BackendServiceException: $message (status: $statusCode)';
}

class BackendService {
  String baseUrl;
  final http.Client _client;
  static const _timeout = Duration(seconds: 30);

  BackendService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------

  Future<bool> healthCheck() async {
    try {
      final response = await _get('/api/health');
      return response['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Agents
  // ---------------------------------------------------------------------------

  Future<List<Agent>> getAgents() async {
    final response = await _get('/api/agents');
    return (response as List).map((j) => Agent.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ---------------------------------------------------------------------------
  // Conversations
  // ---------------------------------------------------------------------------

  Future<List<Conversation>> getConversations() async {
    final response = await _get('/api/conversations');
    return (response as List)
        .map((j) => Conversation.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<ConversationDetail> getConversation(String id) async {
    final response = await _get('/api/conversations/$id');
    return ConversationDetail.fromJson(response as Map<String, dynamic>);
  }

  Future<Conversation> createConversation({
    required String agentId,
    String? title,
  }) async {
    final body = <String, dynamic>{'agentId': agentId};
    if (title != null) body['title'] = title;
    final response = await _post('/api/conversations', body);
    return Conversation.fromJson(response as Map<String, dynamic>);
  }

  Future<Conversation> updateConversation(
    String id, {
    String? title,
    String? agentId,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (agentId != null) body['agentId'] = agentId;
    final response = await _patch('/api/conversations/$id', body);
    return Conversation.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteConversation(String id) async {
    await _delete('/api/conversations/$id');
  }

  // ---------------------------------------------------------------------------
  // Integrations
  // ---------------------------------------------------------------------------

  Future<IntegrationsResponse> getIntegrations() async {
    final response = await _get('/api/integrations');
    return IntegrationsResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<IntegrationsResponse> setFigmaToken(String token) async {
    final response = await _put('/api/integrations/figma', {'token': token});
    return IntegrationsResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<IntegrationsResponse> removeFigmaToken() async {
    final response = await _delete('/api/integrations/figma');
    return IntegrationsResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<void> startClaudeAuth() async {
    await _post('/api/integrations/claude/auth', {});
  }

  Future<ClaudeAuthInfo> getClaudeStatus() async {
    final response = await _get('/api/integrations/claude/status');
    return ClaudeAuthInfo.fromJson(response as Map<String, dynamic>);
  }

  Future<IntegrationsResponse> removeClaudeAuth() async {
    final response = await _delete('/api/integrations/claude');
    return IntegrationsResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<void> startJiraAuth() async {
    await _post('/api/integrations/jira/auth', {});
  }

  Future<IntegrationStatus> getJiraStatus() async {
    final response = await _get('/api/integrations/jira/status');
    return IntegrationStatus.fromJson(response as Map<String, dynamic>);
  }

  Future<IntegrationsResponse> removeJiraAuth() async {
    final response = await _delete('/api/integrations/jira');
    return IntegrationsResponse.fromJson(response as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // HTTP helpers
  // ---------------------------------------------------------------------------

  Future<dynamic> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.get(uri).timeout(_timeout);
    return _handleResponse(response);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .post(uri, headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(_timeout);
    return _handleResponse(response);
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .put(uri, headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(_timeout);
    return _handleResponse(response);
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .patch(uri, headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(_timeout);
    return _handleResponse(response);
  }

  Future<dynamic> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.delete(uri).timeout(_timeout);
    return _handleResponse(response);
  }

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String message;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['error'] as String? ?? response.reasonPhrase ?? 'Unknown error';
    } catch (_) {
      message = response.reasonPhrase ?? 'Unknown error';
    }

    throw BackendServiceException(message, statusCode: response.statusCode);
  }

  void dispose() {
    _client.close();
  }
}
