import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/message.dart';
import '../../theme/app_theme.dart';

class ToolUseBlockView extends StatefulWidget {
  final ToolUseBlock data;

  const ToolUseBlockView({super.key, required this.data});

  @override
  State<ToolUseBlockView> createState() => _ToolUseBlockViewState();
}

class _ToolUseBlockViewState extends State<ToolUseBlockView>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.data.isCollapsed;
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
  }

  Color get _toolColor => AppColors.toolColor(widget.data.name);
  bool get _isRunning => widget.data.result == null;
  bool get _hasError => widget.data.result?.error != null;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle(brightness),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.borderForBrightness(brightness),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          if (_isExpanded) ...[
            Divider(
              height: 0.5,
              thickness: 0.5,
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
              color: AppColors.borderForBrightness(brightness),
            ),
            _buildExpandedContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Tool icon with colored background
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _toolColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                AppIcons.toolIcon(widget.data.name),
                size: 12,
                color: _toolColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Tool name
            Text(
              widget.data.name,
              style: AppTypography.toolName,
            ),
            const SizedBox(width: AppSpacing.sm),

            // Tool summary
            Expanded(
              child: Text(
                _toolSummary,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Status indicator
            if (_isRunning)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                _hasError ? Icons.cancel : Icons.check_circle,
                size: 14,
                color: _hasError ? AppColors.error : AppColors.success,
              ),
            const SizedBox(width: AppSpacing.sm),

            // Chevron
            Icon(
              _isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input section
          _buildSection(
            label: 'INPUT',
            content: _formatJSON(widget.data.input),
            color: AppColors.codeText,
          ),
          if (widget.data.result != null) ...[
            const SizedBox(height: AppSpacing.md),
            // Output/error section
            _buildSection(
              label: 'OUTPUT',
              content: widget.data.result!.error ??
                  widget.data.result!.output ??
                  'No output',
              color: _hasError ? AppColors.error : AppColors.codeText,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String label,
    required String content,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceCode,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                content,
                style: AppTypography.toolDetail.copyWith(color: color),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _toolSummary {
    try {
      final json = jsonDecode(widget.data.input) as Map<String, dynamic>;
      if (json.containsKey('file_path')) {
        final path = json['file_path'] as String;
        return path.split('/').last;
      }
      if (json.containsKey('command')) {
        final cmd = json['command'] as String;
        return cmd.length > 50 ? cmd.substring(0, 50) : cmd;
      }
      if (json.containsKey('pattern')) {
        return json['pattern'] as String;
      }
    } catch (_) {}
    return '';
  }

  String _formatJSON(String input) {
    try {
      final obj = jsonDecode(input);
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return input;
    }
  }
}
