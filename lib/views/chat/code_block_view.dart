import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

import '../../theme/app_theme.dart';

class CodeBlockView extends StatefulWidget {
  final String code;
  final String language;

  const CodeBlockView({
    super.key,
    required this.code,
    required this.language,
  });

  @override
  State<CodeBlockView> createState() => _CodeBlockViewState();
}

class _CodeBlockViewState extends State<CodeBlockView> {
  bool _copied = false;

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceCode,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language label and copy button
          if (widget.language.isNotEmpty) _buildHeader(),

          // Code content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              widget.language.isEmpty ? AppSpacing.md : AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: HighlightView(
              widget.code,
              language: _mapLanguage(widget.language),
              theme: atomOneDarkTheme,
              padding: EdgeInsets.zero,
              textStyle: AppTypography.codeFont.copyWith(
                color: AppColors.codeText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.language,
            style: AppTypography.toolDetail.copyWith(
              color: AppColors.codeText.withValues(alpha: 0.6),
            ),
          ),
          _buildCopyButton(),
        ],
      ),
    );
  }

  Widget _buildCopyButton() {
    return GestureDetector(
      onTap: _copyToClipboard,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _copied ? AppIcons.check : AppIcons.copy,
            size: 14,
            color: _copied
                ? AppColors.success
                : AppColors.codeText.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            _copied ? 'Copied' : 'Copy',
            style: AppTypography.toolDetail.copyWith(
              color: _copied
                  ? AppColors.success
                  : AppColors.codeText.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Map common language aliases to highlight.js language names
  String _mapLanguage(String language) {
    return switch (language.toLowerCase()) {
      'js' => 'javascript',
      'ts' => 'typescript',
      'py' => 'python',
      'rb' => 'ruby',
      'sh' || 'bash' || 'zsh' => 'bash',
      'yml' => 'yaml',
      'md' => 'markdown',
      'objc' || 'objective-c' => 'objectivec',
      '' => 'plaintext',
      _ => language.toLowerCase(),
    };
  }
}
