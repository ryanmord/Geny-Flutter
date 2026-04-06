import 'dart:convert';

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  List<ContentBlock> content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChatMessage && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

sealed class ContentBlock {
  const ContentBlock();
}

class TextBlock extends ContentBlock {
  final String text;
  const TextBlock(this.text);
}

class CodeBlock extends ContentBlock {
  final String language;
  final String code;
  const CodeBlock({required this.language, required this.code});
}

class ToolUseBlock extends ContentBlock {
  final String id;
  final String name;
  final String input;
  ToolResultData? result;
  bool isCollapsed;

  ToolUseBlock({
    required this.id,
    required this.name,
    required this.input,
    this.result,
    this.isCollapsed = false,
  });
}

class ToolResultData {
  final String? output;
  final String? error;

  const ToolResultData({this.output, this.error});
}

extension ContentBlockFromJson on ContentBlock {
  static ContentBlock fromServerBlock(Map<String, dynamic> block) {
    final type = block['type'] as String;
    switch (type) {
      case 'text':
        return TextBlock(block['text'] as String);
      case 'code_block':
        return CodeBlock(
          language: block['language'] as String? ?? '',
          code: block['code'] as String? ?? '',
        );
      case 'tool_use':
        return ToolUseBlock(
          id: block['toolName'] as String? ?? '',
          name: block['toolName'] as String? ?? '',
          input: block['input'] != null
              ? const JsonEncoder.withIndent('  ')
                  .convert(block['input'])
              : '{}',
          result: block['result'] != null
              ? ToolResultData(
                  output: (block['result'] as Map<String, dynamic>)['output']
                      as String?,
                  error: (block['result'] as Map<String, dynamic>)['error']
                      as String?,
                )
              : null,
        );
      default:
        return TextBlock('[Unknown block type: $type]');
    }
  }
}
