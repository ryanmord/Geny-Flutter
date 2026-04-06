import 'package:flutter/material.dart';

import '../../models/message.dart';
import '../../theme/app_theme.dart';
import 'markdown_text_view.dart';
import 'code_block_view.dart';
import 'tool_use_block_view.dart';

class MessageBubbleView extends StatelessWidget {
  final ChatMessage message;

  const MessageBubbleView({super.key, required this.message});

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(context),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _buildContent(context)),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _isUser
            ? AppColors.userAvatar.withValues(alpha: 0.15)
            : AppColors.assistantAvatar.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        _isUser ? AppIcons.person : AppIcons.sparkles,
        size: 14,
        color: _isUser ? AppColors.userAvatar : AppColors.assistantAvatar,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role label + timestamp
        Row(
          children: [
            Text(
              _isUser ? 'You' : 'Assistant',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Content blocks
        ...message.content.map((block) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildBlock(block),
            )),
      ],
    );
  }

  Widget _buildBlock(ContentBlock block) {
    return switch (block) {
      TextBlock(text: final text) => MarkdownTextView(text: text),
      CodeBlock(code: final code, language: final lang) => CodeBlockView(
          code: code,
          language: lang,
        ),
      ToolUseBlock() => ToolUseBlockView(data: block),
    };
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }
}
