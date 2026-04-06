import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../view_models/agent_picker_view_model.dart';
import '../../view_models/chat_view_model.dart';

class InputBarView extends StatefulWidget {
  const InputBarView({super.key});

  @override
  State<InputBarView> createState() => _InputBarViewState();
}

class _InputBarViewState extends State<InputBarView> {
  final _controller = TextEditingController();
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: _handleKeyEvent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _sendMessage();
      return KeyEventResult.handled; // Consume the event to prevent newline
    }

    return KeyEventResult.ignored;
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final chatVM = context.read<ChatViewModel>();
    final agentVM = context.read<AgentPickerViewModel>();

    if (chatVM.isStreaming) return;

    chatVM.sendMessage(
      text,
      agentId: agentVM.selectedAgentId,
      workingDirectory: chatVM.workingDirectory,
    );

    _controller.clear();
    _focusNode.requestFocus();
  }

  void _cancelStream() {
    context.read<ChatViewModel>().cancelStream();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised(brightness),
        border: Border(
          top: BorderSide(
            color: AppColors.borderForBrightness(brightness),
            width: 0.5,
          ),
        ),
      ),
      child: Consumer<ChatViewModel>(
        builder: (context, chatVM, _) {
          final isStreaming = chatVM.isStreaming;

          // Auto-focus when conversation is active
          if (chatVM.currentConversationId != null && !isStreaming) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
            });
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    enabled: !isStreaming,
                    style: AppTypography.inputText,
                    decoration: InputDecoration(
                      hintText:
                          isStreaming ? 'Generating...' : 'Message Geny...',
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.35),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: AppColors.borderForBrightness(brightness),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: AppColors.borderForBrightness(brightness),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Send / Stop button
              if (isStreaming)
                IconButton(
                  onPressed: _cancelStream,
                  icon: const Icon(Icons.stop_circle, size: 24),
                  color: AppColors.error,
                  tooltip: 'Stop generating',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                )
              else
                IconButton(
                  onPressed:
                      _controller.text.trim().isNotEmpty ? _sendMessage : null,
                  icon: const Icon(AppIcons.send, size: 20),
                  tooltip: 'Send message',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  style: IconButton.styleFrom(
                    backgroundColor: _controller.text.trim().isNotEmpty
                        ? AppColors.accent
                        : null,
                    foregroundColor: _controller.text.trim().isNotEmpty
                        ? Colors.white
                        : null,
                    disabledBackgroundColor:
                        AppColors.borderForBrightness(brightness),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

}
