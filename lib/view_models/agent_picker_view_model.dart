import 'package:flutter/foundation.dart';

import '../models/agent.dart';
import '../services/backend_service.dart';

class AgentPickerViewModel extends ChangeNotifier {
  final BackendService _backendService;

  AgentPickerViewModel({required BackendService backendService})
      : _backendService = backendService;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<Agent> _agents = [];
  List<Agent> get agents => List.unmodifiable(_agents);

  String? _selectedAgentId;
  String? get selectedAgentId => _selectedAgentId;

  Agent? get selectedAgent {
    if (_selectedAgentId == null) return null;
    return _agents.where((a) => a.id == _selectedAgentId).firstOrNull;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> loadAgents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _agents = await _backendService.getAgents();
      // Auto-select first agent if none selected
      if (_selectedAgentId == null && _agents.isNotEmpty) {
        _selectedAgentId = _agents.first.id;
      }
    } on BackendServiceException catch (_) {
      // Keep existing agents on error
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  void selectAgent(String id) {
    if (_selectedAgentId == id) return;
    _selectedAgentId = id;
    notifyListeners();
  }
}
