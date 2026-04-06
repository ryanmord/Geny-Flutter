import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'platform_utils.dart';

enum BackendState { stopped, starting, running, error }

class BackendProcessManager extends ChangeNotifier {
  Process? _process;
  BackendState _state = BackendState.stopped;
  int? _port;
  String? _errorMessage;
  final _stateController = StreamController<BackendState>.broadcast();

  BackendState get state => _state;
  int? get port => _port;
  String? get errorMessage => _errorMessage;
  String? get baseUrl => _port != null ? 'http://127.0.0.1:$_port' : null;
  Stream<BackendState> get stateStream => _stateController.stream;

  Future<void> startBackend() async {
    if (_state == BackendState.running || _state == BackendState.starting) {
      return;
    }

    _setState(BackendState.starting);
    _errorMessage = null;

    // Find Node.js
    final nodePath = await PlatformUtils.findNodePath();
    if (nodePath == null) {
      _errorMessage = 'Node.js not found. Please install Node.js to use Geny.';
      _setState(BackendState.error);
      return;
    }

    // Find backend directory
    final backendPath = await PlatformUtils.findBackendPath();
    if (backendPath == null) {
      _errorMessage = 'Backend not found.';
      _setState(BackendState.error);
      return;
    }

    try {
      final isProduction = await _isProductionBuild(backendPath);

      if (isProduction) {
        _process = await Process.start(
          nodePath,
          ['dist/index.js'],
          workingDirectory: backendPath,
          environment: {'NODE_ENV': 'production'},
        );
      } else {
        // Development: use npx tsx
        final npxPath = PlatformUtils.npxPath(nodePath);
        _process = await Process.start(
          npxPath,
          ['tsx', 'src/index.ts'],
          workingDirectory: backendPath,
        );
      }

      // Listen for port on stdout
      final portCompleter = Completer<int>();

      _process!.stdout.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          final match = RegExp(r'GENY_PORT=(\d+)').firstMatch(line);
          if (match != null && !portCompleter.isCompleted) {
            portCompleter.complete(int.parse(match.group(1)!));
          }
        }
      });

      _process!.stderr.transform(utf8.decoder).listen((data) {
        // Log stderr in debug mode
        assert(() {
          // ignore: avoid_print
          print('[backend stderr] $data');
          return true;
        }());
      });

      _process!.exitCode.then((code) {
        if (_state == BackendState.running || _state == BackendState.starting) {
          _errorMessage = 'Backend process exited with code $code';
          _setState(BackendState.error);
        }
      });

      // Wait for port with timeout
      _port = await portCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Backend did not report port within 30 seconds');
        },
      );

      // Poll health check until ready
      await _waitForHealth();
      _setState(BackendState.running);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(BackendState.error);
      await stopBackend();
    }
  }

  Future<void> _waitForHealth() async {
    for (var i = 0; i < 30; i++) {
      try {
        final response = await HttpClient()
            .getUrl(Uri.parse('http://127.0.0.1:$_port/api/health'))
            .then((req) => req.close())
            .timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) return;
      } catch (_) {
        // Not ready yet
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    throw Exception('Backend health check failed after 15 seconds');
  }

  Future<bool> _isProductionBuild(String backendPath) async {
    return Directory('$backendPath/dist').existsSync() &&
        !File('$backendPath/src/index.ts').existsSync();
  }

  Future<void> stopBackend() async {
    if (_process != null) {
      _process!.kill(ProcessSignal.sigterm);

      // Give it a moment to shut down gracefully, then force kill
      await Future.delayed(const Duration(seconds: 2));
      try {
        _process!.kill(ProcessSignal.sigkill);
      } catch (_) {
        // Process may have already exited
      }

      _process = null;
    }
    _port = null;
    _setState(BackendState.stopped);
  }

  void _setState(BackendState newState) {
    _state = newState;
    _stateController.add(newState);
    notifyListeners();
  }

  @override
  void dispose() {
    stopBackend();
    _stateController.close();
    super.dispose();
  }
}
