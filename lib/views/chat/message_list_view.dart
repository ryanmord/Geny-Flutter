import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../view_models/chat_view_model.dart';
import 'message_bubble_view.dart';

class MessageListView extends StatefulWidget {
  const MessageListView({super.key});

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  final _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  bool _isAutoScrolling = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final atBottom = (maxScroll - currentScroll) < 50;

    if (_showScrollToBottom == atBottom) {
      setState(() => _showScrollToBottom = !atBottom);
    }
    _isAutoScrolling = atBottom;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, vm, _) {
        // Auto-scroll when streaming
        if (_isAutoScrolling && vm.messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && _isAutoScrolling) {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            }
          });
        }

        return Stack(
          children: [
            if (vm.messages.isEmpty && !vm.isStreaming)
              _buildEmptyState(context)
            else
              _buildMessageList(context, vm),

            // Error banner
            if (vm.error != null) _buildErrorBanner(context, vm),

            // Scroll to bottom FAB
            if (_showScrollToBottom)
              Positioned(
                bottom: AppSpacing.md,
                right: AppSpacing.md,
                child: FloatingActionButton.small(
                  onPressed: _scrollToBottom,
                  backgroundColor: AppColors.surfaceRaised(
                    Theme.of(context).brightness,
                  ),
                  child: const Icon(AppIcons.chevronDown, size: 20),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMessageList(BuildContext context, ChatViewModel vm) {
    final itemCount = vm.messages.length +
        (vm.isStreaming && vm.streamingText.isNotEmpty ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < vm.messages.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: MessageBubbleView(message: vm.messages[index]),
          );
        }

        // Streaming indicator with partial text
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: _buildStreamingIndicator(context, vm),
        );
      },
    );
  }

  Widget _buildStreamingIndicator(BuildContext context, ChatViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status text
        if (vm.statusText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  vm.statusText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.sparkles,
            size: 40,
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Type a message below to get started',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, ChatViewModel vm) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          color: AppColors.error.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(AppIcons.error, size: 16, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  vm.error!,
                  style: const TextStyle(fontSize: 13, color: AppColors.error),
                ),
              ),
              IconButton(
                icon: const Icon(AppIcons.close, size: 16),
                onPressed: () {
                  // Clear error by sending an empty action - error clears on next send
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
