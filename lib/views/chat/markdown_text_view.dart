import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import 'code_block_view.dart';

class MarkdownTextView extends StatelessWidget {
  final String text;

  const MarkdownTextView({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href));
        }
      },
      styleSheet: _buildStyleSheet(context),
      builders: {
        'code': _InlineCodeBuilder(),
        'pre': _CodeBlockBuilder(),
      },
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return MarkdownStyleSheet(
      // Paragraphs
      p: TextStyle(fontSize: 14, height: 1.5, color: textColor),

      // Headings
      h1: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.3,
      ),
      h2: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.3,
      ),
      h3: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.3,
      ),
      h4: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.3,
      ),
      h5: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.3,
      ),
      h6: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.3,
      ),

      // Heading padding
      h1Padding: const EdgeInsets.only(top: 8, bottom: 2),
      h2Padding: const EdgeInsets.only(top: 6, bottom: 2),
      h3Padding: const EdgeInsets.only(top: 4, bottom: 2),
      h4Padding: const EdgeInsets.only(top: 2, bottom: 2),
      h5Padding: const EdgeInsets.only(top: 2, bottom: 2),
      h6Padding: const EdgeInsets.only(top: 2, bottom: 2),

      // Code
      code: AppTypography.codeFont.copyWith(
        backgroundColor: AppColors.surfaceCode,
        color: AppColors.codeText,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.surfaceCode,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      codeblockPadding: const EdgeInsets.all(AppSpacing.md),

      // Blockquote
      blockquote: TextStyle(
        color: textColor.withValues(alpha: 0.7),
        fontSize: 14,
        height: 1.5,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: textColor.withValues(alpha: 0.3),
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),

      // Lists
      listBullet: TextStyle(fontSize: 14, color: textColor),

      // Table
      tableHead: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: textColor,
      ),
      tableBody: TextStyle(fontSize: 13, color: textColor),
      tableBorder: TableBorder.all(
        color: textColor.withValues(alpha: 0.15),
        width: 1,
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: textColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),

      // Links
      a: const TextStyle(
        color: AppColors.accent,
        decoration: TextDecoration.underline,
      ),

      // Strong / emphasis
      strong: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
    );
  }
}

// Inline code builder - renders `code` with background
class _InlineCodeBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    // Only handle inline code, not code blocks
    if (element.attributes['class'] != null) return null;

    final text = element.textContent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.surfaceCode,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.codeFont.copyWith(
          color: AppColors.codeText,
          fontSize: 13,
        ),
      ),
    );
  }
}

// Code block builder - renders fenced code blocks with syntax highlighting
class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    String? language;
    String code = element.textContent;

    // Extract language from class attribute (e.g., "language-dart")
    final codeElement = element.children?.whereType<md.Element>().firstOrNull;
    if (codeElement != null) {
      final className = codeElement.attributes['class'];
      if (className != null && className.startsWith('language-')) {
        language = className.substring('language-'.length);
      }
      code = codeElement.textContent;
    }

    // Remove trailing newline
    if (code.endsWith('\n')) {
      code = code.substring(0, code.length - 1);
    }

    return CodeBlockView(
      code: code,
      language: language ?? '',
    );
  }
}
