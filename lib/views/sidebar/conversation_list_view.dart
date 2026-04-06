import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../view_models/conversation_list_view_model.dart';
import 'conversation_row.dart';
import 'new_conversation_button.dart';

class ConversationListView extends StatelessWidget {
  final void Function(String id) onSelectConversation;
  final VoidCallback onNewConversation;

  const ConversationListView({
    super.key,
    required this.onSelectConversation,
    required this.onNewConversation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: NewConversationButton(onPressed: onNewConversation),
        ),
        Expanded(
          child: Consumer<ConversationListViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.conversations.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              if (vm.conversations.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                itemCount: vm.conversations.length,
                itemBuilder: (context, index) {
                  final conversation = vm.conversations[index];
                  return ConversationRow(
                    conversation: conversation,
                    isSelected: conversation.id == vm.selectedConversationId,
                    onTap: () => onSelectConversation(conversation.id),
                    onRename: (title) => vm.updateConversation(
                      conversation.id,
                      title: title,
                    ),
                    onDelete: () => _confirmDelete(context, vm, conversation.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.sparkles,
              size: 32,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Start a new conversation to get going',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.35),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ConversationListViewModel vm,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure you want to delete this conversation? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              vm.deleteConversation(id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
