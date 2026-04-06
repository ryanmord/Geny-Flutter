import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../view_models/agent_picker_view_model.dart';
import '../view_models/chat_view_model.dart';
import '../view_models/conversation_list_view_model.dart';
import 'chat/chat_view.dart';
import 'sidebar/conversation_list_view.dart';
import 'settings/settings_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  double _sidebarWidth = 260;
  static const _minSidebarWidth = 200.0;
  static const _maxSidebarWidth = 400.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load initial data
    final conversationListVM = context.read<ConversationListViewModel>();
    final agentPickerVM = context.read<AgentPickerViewModel>();
    conversationListVM.loadConversations();
    agentPickerVM.loadAgents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onNewConversation() async {
    final agentVM = context.read<AgentPickerViewModel>();
    final conversationListVM = context.read<ConversationListViewModel>();
    final chatVM = context.read<ChatViewModel>();

    final agentId = agentVM.selectedAgentId;
    if (agentId == null) return;

    final conversation = await conversationListVM.createConversation(
      agentId: agentId,
    );
    if (conversation != null) {
      chatVM.loadConversation(conversation.id);
    }
  }

  void _onSelectConversation(String id) {
    final conversationListVM = context.read<ConversationListViewModel>();
    final chatVM = context.read<ChatViewModel>();
    conversationListVM.selectConversation(id);
    chatVM.loadConversation(id);
  }

  void _onDeselectConversation() {
    final conversationListVM = context.read<ConversationListViewModel>();
    final chatVM = context.read<ChatViewModel>();
    conversationListVM.selectConversation(null);
    chatVM.clearConversation();
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => const SettingsView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: Column(
        children: [
          // Draggable title bar area
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (_) {},
            child: Container(
              height: 28,
              color: AppColors.surfaceOverlay(brightness),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Sidebar
                SizedBox(
                  width: _sidebarWidth,
                  child: _buildSidebar(brightness),
                ),
                // Drag handle
                GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _sidebarWidth = (_sidebarWidth + details.delta.dx)
                          .clamp(_minSidebarWidth, _maxSidebarWidth);
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: Container(
                      width: 1,
                      color: AppColors.borderForBrightness(brightness),
                    ),
                  ),
                ),
                // Detail panel
                Expanded(child: _buildDetailPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(Brightness brightness) {
    return Container(
      color: AppColors.surfaceOverlay(brightness),
      child: Column(
        children: [
          Expanded(
            child: ConversationListView(
              onSelectConversation: _onSelectConversation,
              onNewConversation: _onNewConversation,
            ),
          ),
          // Bottom bar with settings
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.borderForBrightness(brightness),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(AppIcons.settings, size: 18),
                  onPressed: _openSettings,
                  tooltip: 'Settings',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    return Consumer<ConversationListViewModel>(
      builder: (context, vm, _) {
        if (vm.selectedConversationId == null) {
          return _buildEmptyState();
        }
        return ChatView(
          conversationId: vm.selectedConversationId!,
          onClose: _onDeselectConversation,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final brightness = Theme.of(context).brightness;
    return Container(
      color: AppColors.surfaceRaised(brightness),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.sparkles,
              size: 48,
              color: AppColors.accent.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Select a conversation or create a new one',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
