import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'services/backend_process_manager.dart';
import 'services/backend_service.dart';
import 'services/websocket_service.dart';
import 'theme/app_theme.dart';
import 'view_models/agent_picker_view_model.dart';
import 'view_models/chat_view_model.dart';
import 'view_models/conversation_list_view_model.dart';
import 'view_models/settings_view_model.dart';
import 'views/app_shell.dart';
import 'views/settings/settings_view.dart';

class GenyApp extends StatefulWidget {
  const GenyApp({super.key});

  @override
  State<GenyApp> createState() => _GenyAppState();
}

class _GenyAppState extends State<GenyApp> with WindowListener {
  final _processManager = BackendProcessManager();
  late final BackendService _backendService;
  final _webSocketService = WebSocketService();
  late final ChatViewModel _chatViewModel;
  late final ConversationListViewModel _conversationListViewModel;
  late final AgentPickerViewModel _agentPickerViewModel;
  late final SettingsViewModel _settingsViewModel;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    _backendService = BackendService(baseUrl: '');
    _chatViewModel = ChatViewModel(
      backendService: _backendService,
      webSocketService: _webSocketService,
    );
    _conversationListViewModel = ConversationListViewModel(
      backendService: _backendService,
    );
    _agentPickerViewModel = AgentPickerViewModel(
      backendService: _backendService,
    );
    _settingsViewModel = SettingsViewModel(
      backendService: _backendService,
    );
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
  void onWindowClose() async {
    // Clean shutdown
    _webSocketService.disconnect();
    _processManager.dispose();
    await windowManager.destroy();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _chatViewModel.dispose();
    _conversationListViewModel.dispose();
    _agentPickerViewModel.dispose();
    _settingsViewModel.dispose();
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
        ChangeNotifierProvider.value(value: _chatViewModel),
        ChangeNotifierProvider.value(value: _conversationListViewModel),
        ChangeNotifierProvider.value(value: _agentPickerViewModel),
        ChangeNotifierProvider.value(value: _settingsViewModel),
      ],
      child: _buildApp(),
    );
  }

  Widget _buildApp() {
    return MaterialApp(
      title: 'Geny',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      shortcuts: {
        ..._shortcuts(),
      },
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
            BackendState.running => const _ShortcutActions(child: AppShell()),
          };
        },
      ),
    );
  }

  Map<ShortcutActivator, Intent> _shortcuts() {
    return {
      // Cmd/Ctrl + N → New conversation
      const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
          const _NewConversationIntent(),
      const SingleActivator(LogicalKeyboardKey.keyN, control: true):
          const _NewConversationIntent(),
      // Cmd/Ctrl + , → Settings
      const SingleActivator(LogicalKeyboardKey.comma, meta: true):
          const _OpenSettingsIntent(),
      const SingleActivator(LogicalKeyboardKey.comma, control: true):
          const _OpenSettingsIntent(),
      // Cmd/Ctrl + W → Close conversation
      const SingleActivator(LogicalKeyboardKey.keyW, meta: true):
          const _CloseConversationIntent(),
      const SingleActivator(LogicalKeyboardKey.keyW, control: true):
          const _CloseConversationIntent(),
      // Escape → Cancel streaming
      const SingleActivator(LogicalKeyboardKey.escape):
          const _EscapeIntent(),
    };
  }
}

// ---------------------------------------------------------------------------
// Shortcut Intents & Actions
// ---------------------------------------------------------------------------

class _NewConversationIntent extends Intent {
  const _NewConversationIntent();
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

class _CloseConversationIntent extends Intent {
  const _CloseConversationIntent();
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

class _ShortcutActions extends StatelessWidget {
  final Widget child;
  const _ShortcutActions({required this.child});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        _NewConversationIntent: CallbackAction<_NewConversationIntent>(
          onInvoke: (_) {
            final agentVM = context.read<AgentPickerViewModel>();
            final conversationListVM = context.read<ConversationListViewModel>();
            final chatVM = context.read<ChatViewModel>();

            final agentId = agentVM.selectedAgentId;
            if (agentId == null) return null;

            conversationListVM
                .createConversation(agentId: agentId)
                .then((conversation) {
              if (conversation != null) {
                chatVM.loadConversation(conversation.id);
              }
            });
            return null;
          },
        ),
        _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
          onInvoke: (_) {
            showDialog(
              context: context,
              builder: (_) => const _SettingsDialogWrapper(),
            );
            return null;
          },
        ),
        _CloseConversationIntent: CallbackAction<_CloseConversationIntent>(
          onInvoke: (_) {
            context.read<ConversationListViewModel>().selectConversation(null);
            context.read<ChatViewModel>().clearConversation();
            return null;
          },
        ),
        _EscapeIntent: CallbackAction<_EscapeIntent>(
          onInvoke: (_) {
            final chatVM = context.read<ChatViewModel>();
            if (chatVM.isStreaming) {
              chatVM.cancelStream();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            return null;
          },
        ),
      },
      child: child,
    );
  }
}

class _SettingsDialogWrapper extends StatelessWidget {
  const _SettingsDialogWrapper();

  @override
  Widget build(BuildContext context) {
    return const SettingsView();
  }
}

// ---------------------------------------------------------------------------
// Loading & Error Screens
// ---------------------------------------------------------------------------

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
