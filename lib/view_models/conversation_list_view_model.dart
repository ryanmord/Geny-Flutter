import 'package:flutter/foundation.dart';

import '../models/conversation.dart';
import '../services/backend_service.dart';

class ConversationListViewModel extends ChangeNotifier {
  final BackendService _backendService;

  ConversationListViewModel({required BackendService backendService})
      : _backendService = backendService;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<Conversation> _conversations = [];
  List<Conversation> get conversations => List.unmodifiable(_conversations);

  String? _selectedConversationId;
  String? get selectedConversationId => _selectedConversationId;

  Conversation? get selectedConversation {
    if (_selectedConversationId == null) return null;
    return _conversations
        .where((c) => c.id == _selectedConversationId)
        .firstOrNull;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _backendService.getConversations();
      _sortConversations();
    } on BackendServiceException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load conversations';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<Conversation?> createConversation({
    required String agentId,
    String? title,
  }) async {
    try {
      final conversation = await _backendService.createConversation(
        agentId: agentId,
        title: title,
      );
      _conversations.insert(0, conversation);
      _selectedConversationId = conversation.id;
      notifyListeners();
      return conversation;
    } on BackendServiceException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<void> updateConversation(String id, {String? title}) async {
    try {
      final updated = await _backendService.updateConversation(id, title: title);
      final index = _conversations.indexWhere((c) => c.id == id);
      if (index >= 0) {
        _conversations[index] = updated;
        _sortConversations();
        notifyListeners();
      }
    } on BackendServiceException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      await _backendService.deleteConversation(id);
      _conversations.removeWhere((c) => c.id == id);
      if (_selectedConversationId == id) {
        _selectedConversationId = null;
      }
      notifyListeners();
    } on BackendServiceException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  void selectConversation(String? id) {
    if (_selectedConversationId == id) return;
    _selectedConversationId = id;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _sortConversations() {
    _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
