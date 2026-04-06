import 'package:flutter/material.dart';

import '../../models/conversation.dart';
import '../../theme/app_theme.dart';

class ConversationRow extends StatefulWidget {
  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(String title) onRename;
  final VoidCallback onDelete;

  const ConversationRow({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<ConversationRow> createState() => _ConversationRowState();
}

class _ConversationRowState extends State<ConversationRow> {
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.conversation.title);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editController.text = widget.conversation.title;
    });
  }

  void _submitEdit() {
    final newTitle = _editController.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.conversation.title) {
      widget.onRename(newTitle);
    }
    setState(() => _isEditing = false);
  }

  void _cancelEdit() {
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _startEditing,
      onSecondaryTapUp: (details) => _showContextMenu(context, details),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.accentSubtle
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: _isEditing ? _buildEditField() : _buildContent(brightness),
      ),
    );
  }

  Widget _buildContent(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.conversation.title,
          style: AppTypography.conversationTitle.copyWith(
            color: widget.isSelected
                ? AppColors.accent
                : Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          _formatRelativeTime(widget.conversation.updatedAt),
          style: AppTypography.conversationDate.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildEditField() {
    return TextField(
      controller: _editController,
      autofocus: true,
      style: AppTypography.conversationTitle,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
      ),
      onSubmitted: (_) => _submitEdit(),
      onEditingComplete: _submitEdit,
      onTapOutside: (_) => _cancelEdit(),
    );
  }

  void _showContextMenu(BuildContext context, TapUpDetails details) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          onTap: _startEditing,
          child: const Row(
            children: [
              Icon(AppIcons.edit, size: 16),
              SizedBox(width: AppSpacing.sm),
              Text('Rename'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: widget.onDelete,
          child: const Row(
            children: [
              Icon(AppIcons.close, size: 16, color: AppColors.error),
              SizedBox(width: AppSpacing.sm),
              Text('Delete', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatRelativeTime(String isoString) {
    final date = DateTime.tryParse(isoString);
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.month}/${date.day}/${date.year}';
  }
}
