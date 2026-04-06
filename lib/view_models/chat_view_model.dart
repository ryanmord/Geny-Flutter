import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/stream_event.dart';
import '../services/backend_service.dart';
import '../services/websocket_service.dart';

const _uuid = Uuid();

class ChatViewModel extends ChangeNotifier {
  final BackendService _backendService;
  final WebSocketService _webSocketService;
  StreamSubscription<StreamEvent>? _eventSubscription;

  ChatViewModel({
    required BackendService backendService,
    required WebSocketService webSocketService,
  })  : _backendService = backendService,
        _webSocketService = webSocketService {
    _eventSubscription = _webSocketService.eventStream.listen(_handleEvent);
  }

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  String _streamingText = '';
  String get streamingText => _streamingText;

  ToolUseBlock? _currentToolUse;
  ToolUseBlock? get currentToolUse => _currentToolUse;

  String? _statusText;
  String? get statusText => _statusText;

  String? _error;
  String? get error => _error;

  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;

  double? _lastCostUsd;
  double? get lastCostUsd => _lastCostUsd;

  double? _lastDurationMs;
  double? get lastDurationMs => _lastDurationMs;

  // ---------------------------------------------------------------------------
  // Conversation management
  // ---------------------------------------------------------------------------

  Future<void> loadConversation(String id) async {
    // Clear state from previous conversation
    _clearStreamingState();
    _messages = [];
    _error = null;
    _currentConversationId = id;
    notifyListeners();

    try {
      final detail = await _backendService.getConversation(id);
      // Only apply if we haven't switched conversations while loading
      if (_currentConversationId != id) return;

      _messages = detail.messages.map(_storedMessageToChatMessage).toList();
      notifyListeners();
    } on BackendServiceException catch (e) {
      if (_currentConversationId != id) return;
      _error = e.message;
      notifyListeners();
    }
  }

  void clearConversation() {
    _clearStreamingState();
    _messages = [];
    _error = null;
    _currentConversationId = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Sending messages
  // ---------------------------------------------------------------------------

  void sendMessage(
    String text, {
    String? agentId,
    String? workingDirectory,
  }) {
    if (_currentConversationId == null || text.trim().isEmpty) return;

    // Add user message to the list immediately
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: [TextBlock(text)],
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _error = null;
    notifyListeners();

    _webSocketService.sendMessage(
      conversationId: _currentConversationId!,
      message: text,
      agentId: agentId,
      workingDirectory: workingDirectory,
    );
  }

  void cancelStream() {
    if (_currentConversationId == null || !_isStreaming) return;
    _webSocketService.cancelStream(_currentConversationId!);
  }

  // ---------------------------------------------------------------------------
  // Event processing
  // ---------------------------------------------------------------------------

  void _handleEvent(StreamEvent event) {
    // Ignore events for non-active conversations
    if (event.conversationId != _currentConversationId) return;

    switch (event) {
      case StreamStart():
        _isStreaming = true;
        _streamingText = '';
        _currentToolUse = null;
        _error = null;
        _statusText = null;
        notifyListeners();

      case StreamDelta(text: final text):
        _streamingText += text;
        notifyListeners();

      case ToolUseStart(toolName: final name, toolInput: final input):
        // Finalize any accumulated streaming text into the current message
        _finalizeStreamingTextBlock();

        _currentToolUse = ToolUseBlock(
          id: _uuid.v4(),
          name: name,
          input: const JsonEncoder.withIndent('  ').convert(input),
        );
        _ensureAssistantMessage().content.add(_currentToolUse!);
        notifyListeners();

      case ToolResult(toolName: final _, output: final output, error: final error):
        if (_currentToolUse != null) {
          _currentToolUse!.result = ToolResultData(
            output: output,
            error: error,
          );
          _currentToolUse!.isCollapsed = true;
          _currentToolUse = null;
        }
        notifyListeners();

      case AssistantMessage(message: final msgJson):
        _finalizeFromServerMessage(msgJson);
        notifyListeners();

      case StreamEnd(costUsd: final cost, durationMs: final duration):
        _finalizeStreamingTextBlock();
        _isStreaming = false;
        _statusText = null;
        _lastCostUsd = cost;
        _lastDurationMs = duration;
        notifyListeners();

      case StatusUpdate(statusText: final text):
        _statusText = text;
        notifyListeners();

      case StreamError(error: final errorMsg):
        _isStreaming = false;
        _error = errorMsg;
        _statusText = null;
        notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the in-progress assistant message, creating one if needed.
  ChatMessage _ensureAssistantMessage() {
    if (_messages.isNotEmpty && _messages.last.role == MessageRole.assistant) {
      return _messages.last;
    }
    final msg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: [],
      timestamp: DateTime.now(),
    );
    _messages.add(msg);
    return msg;
  }

  /// If there's accumulated streaming text, append it as a TextBlock to the
  /// current assistant message and reset the buffer.
  void _finalizeStreamingTextBlock() {
    if (_streamingText.isEmpty) return;
    _ensureAssistantMessage().content.add(TextBlock(_streamingText));
    _streamingText = '';
  }

  /// Replace the current streaming assistant message with the authoritative
  /// server-provided message content.
  void _finalizeFromServerMessage(Map<String, dynamic> msgJson) {
    final blocks = (msgJson['content'] as List<dynamic>?)
            ?.map((b) =>
                ContentBlockFromJson.fromServerBlock(b as Map<String, dynamic>))
            .toList() ??
        [];

    if (_messages.isNotEmpty && _messages.last.role == MessageRole.assistant) {
      _messages.last.content = blocks;
    } else {
      _messages.add(ChatMessage(
        id: msgJson['id'] as String? ?? _uuid.v4(),
        role: MessageRole.assistant,
        content: blocks,
        timestamp: DateTime.now(),
      ));
    }

    _streamingText = '';
    _currentToolUse = null;
  }

  void _clearStreamingState() {
    _isStreaming = false;
    _streamingText = '';
    _currentToolUse = null;
    _statusText = null;
    _lastCostUsd = null;
    _lastDurationMs = null;
  }

  static ChatMessage _storedMessageToChatMessage(StoredMessage stored) {
    return ChatMessage(
      id: stored.id,
      role: stored.role == 'user' ? MessageRole.user : MessageRole.assistant,
      content: stored.content
          .map((b) => ContentBlockFromJson.fromServerBlock(b.toJson()))
          .toList(),
      timestamp: DateTime.tryParse(stored.timestamp) ?? DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Disposal
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
