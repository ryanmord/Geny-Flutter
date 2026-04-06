import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../view_models/conversation_list_view_model.dart';
import '../agents/agent_picker_view.dart';
import '../working_directory_picker.dart';
import 'input_bar_view.dart';
import 'message_list_view.dart';

class ChatView extends StatelessWidget {
  final String conversationId;
  final VoidCallback onClose;

  const ChatView({
    super.key,
    required this.conversationId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      color: AppColors.surfaceRaised(brightness),
      child: Column(
        children: [
          _buildToolbar(context, brightness),
          const Expanded(child: MessageListView()),
          const InputBarView(),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised(brightness),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderForBrightness(brightness),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Agent picker
          const AgentPickerView(),
          const SizedBox(width: AppSpacing.md),
          // Conversation title
          Expanded(
            child: Consumer<ConversationListViewModel>(
              builder: (context, vm, _) {
                final conversation = vm.selectedConversation;
                return Text(
                  conversation?.title ?? 'Conversation',
                  style: AppTypography.conversationTitle,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Working directory picker
          const WorkingDirectoryPicker(),
        ],
      ),
    );
  }
}
