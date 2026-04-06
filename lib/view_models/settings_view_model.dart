import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/integration.dart';
import '../services/backend_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final BackendService _backendService;

  SettingsViewModel({required BackendService backendService})
      : _backendService = backendService;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  IntegrationsResponse? _integrations;
  IntegrationsResponse? get integrations => _integrations;

  ClaudeAuthInfo? _claudeInfo;
  ClaudeAuthInfo? get claudeInfo => _claudeInfo;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAuthenticatingClaude = false;
  bool get isAuthenticatingClaude => _isAuthenticatingClaude;

  bool _isAuthenticatingJira = false;
  bool get isAuthenticatingJira => _isAuthenticatingJira;

  String? _error;
  String? get error => _error;

  Timer? _pollTimer;

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> loadIntegrations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _integrations = await _backendService.getIntegrations();
      if (_integrations!.anthropic.isConnected) {
        _claudeInfo = await _backendService.getClaudeStatus();
      }
    } on BackendServiceException catch (e) {
      _error = e.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Claude Auth
  // ---------------------------------------------------------------------------

  Future<void> authenticateClaude() async {
    _isAuthenticatingClaude = true;
    _error = null;
    notifyListeners();

    try {
      await _backendService.startClaudeAuth();
      _startPollingClaude();
    } on BackendServiceException catch (e) {
      _isAuthenticatingClaude = false;
      _error = e.message;
      notifyListeners();
    }
  }

  void _startPollingClaude() {
    var attempts = 0;
    const maxAttempts = 60; // 2s * 60 = 120s

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      attempts++;
      if (attempts >= maxAttempts) {
        timer.cancel();
        _isAuthenticatingClaude = false;
        _error = 'Authentication timed out';
        notifyListeners();
        return;
      }

      try {
        final info = await _backendService.getClaudeStatus();
        if (info.loggedIn) {
          timer.cancel();
          _claudeInfo = info;
          _isAuthenticatingClaude = false;
          await _refreshIntegrations();
          notifyListeners();
        }
      } catch (_) {
        // Continue polling
      }
    });
  }

  Future<void> disconnectClaude() async {
    try {
      _integrations = await _backendService.removeClaudeAuth();
      _claudeInfo = null;
      notifyListeners();
    } on BackendServiceException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Figma
  // ---------------------------------------------------------------------------

  Future<void> setFigmaToken(String token) async {
    try {
      _integrations = await _backendService.setFigmaToken(token);
      _error = null;
      notifyListeners();
    } on BackendServiceException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> removeFigmaToken() async {
    try {
      _integrations = await _backendService.removeFigmaToken();
      notifyListeners();
    } on BackendServiceException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Jira
  // ---------------------------------------------------------------------------

  Future<void> authenticateJira() async {
    _isAuthenticatingJira = true;
    _error = null;
    notifyListeners();

    try {
      await _backendService.startJiraAuth();
      _startPollingJira();
    } on BackendServiceException catch (e) {
      _isAuthenticatingJira = false;
      _error = e.message;
      notifyListeners();
    }
  }

  void _startPollingJira() {
    var attempts = 0;
    const maxAttempts = 60;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      attempts++;
      if (attempts >= maxAttempts) {
        timer.cancel();
        _isAuthenticatingJira = false;
        _error = 'Authentication timed out';
        notifyListeners();
        return;
      }

      try {
        final status = await _backendService.getJiraStatus();
        if (status.isConnected) {
          timer.cancel();
          _isAuthenticatingJira = false;
          await _refreshIntegrations();
          notifyListeners();
        }
      } catch (_) {
        // Continue polling
      }
    });
  }

  Future<void> disconnectJira() async {
    try {
      _integrations = await _backendService.removeJiraAuth();
      notifyListeners();
    } on BackendServiceException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _refreshIntegrations() async {
    try {
      _integrations = await _backendService.getIntegrations();
    } catch (_) {}
  }

  void cancelPolling() {
    _pollTimer?.cancel();
    _isAuthenticatingClaude = false;
    _isAuthenticatingJira = false;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
