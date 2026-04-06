import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/backend_process_manager.dart';
import 'services/backend_service.dart';
import 'services/websocket_service.dart';

class GenyApp extends StatefulWidget {
  const GenyApp({super.key});

  @override
  State<GenyApp> createState() => _GenyAppState();
}

class _GenyAppState extends State<GenyApp> {
  final _processManager = BackendProcessManager();
  late final BackendService _backendService;
  final _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _backendService = BackendService(baseUrl: '');
    _startBackend();
  }

  Future<void> _startBackend() async {
    await _processManager.startBackend();
    if (_processManager.baseUrl != null) {
      _backendService.baseUrl = _processManager.baseUrl!;
      _webSocketService.connect(_processManager.baseUrl!);
    }
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    _processManager.dispose();
    _backendService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _processManager),
        Provider.value(value: _backendService),
        Provider.value(value: _webSocketService),
      ],
      child: MaterialApp(
        title: 'Geny',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: StreamBuilder<BackendState>(
          stream: _processManager.stateStream,
          initialData: _processManager.state,
          builder: (context, snapshot) {
            final state = snapshot.data ?? BackendState.stopped;
            return switch (state) {
              BackendState.stopped ||
              BackendState.starting =>
                const _LoadingScreen(),
              BackendState.error =>
                _ErrorScreen(message: _processManager.errorMessage ?? 'Unknown error'),
              BackendState.running => const _PlaceholderHome(),
            };
          },
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Starting Geny...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Geny - Connected to backend')),
    );
  }
}
