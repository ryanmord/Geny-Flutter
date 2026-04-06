sealed class StreamEvent {
  final String conversationId;
  const StreamEvent({required this.conversationId});

  factory StreamEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final conversationId = json['conversationId'] as String;

    return switch (type) {
      'stream_start' => StreamStart(conversationId: conversationId),
      'stream_delta' => StreamDelta(
          conversationId: conversationId,
          text: json['text'] as String,
        ),
      'tool_use_start' => ToolUseStart(
          conversationId: conversationId,
          toolName: json['toolName'] as String,
          toolInput: json['toolInput'] as Map<String, dynamic>? ?? {},
        ),
      'tool_result' => ToolResult(
          conversationId: conversationId,
          toolName: json['toolName'] as String,
          output: json['output'] as String?,
          error: json['error'] as String?,
        ),
      'assistant_message' => AssistantMessage(
          conversationId: conversationId,
          message: json['message'] as Map<String, dynamic>,
        ),
      'stream_end' => StreamEnd(
          conversationId: conversationId,
          costUsd: (json['costUsd'] as num?)?.toDouble(),
          durationMs: (json['durationMs'] as num?)?.toDouble(),
        ),
      'status_update' => StatusUpdate(
          conversationId: conversationId,
          statusText: json['statusText'] as String,
        ),
      'stream_error' => StreamError(
          conversationId: conversationId,
          error: json['error'] as String,
        ),
      _ => StreamError(
          conversationId: conversationId,
          error: 'Unknown event type: $type',
        ),
    };
  }
}

class StreamStart extends StreamEvent {
  const StreamStart({required super.conversationId});
}

class StreamDelta extends StreamEvent {
  final String text;
  const StreamDelta({required super.conversationId, required this.text});
}

class ToolUseStart extends StreamEvent {
  final String toolName;
  final Map<String, dynamic> toolInput;
  const ToolUseStart({
    required super.conversationId,
    required this.toolName,
    required this.toolInput,
  });
}

class ToolResult extends StreamEvent {
  final String toolName;
  final String? output;
  final String? error;
  const ToolResult({
    required super.conversationId,
    required this.toolName,
    this.output,
    this.error,
  });
}

class AssistantMessage extends StreamEvent {
  final Map<String, dynamic> message;
  const AssistantMessage({
    required super.conversationId,
    required this.message,
  });
}

class StreamEnd extends StreamEvent {
  final double? costUsd;
  final double? durationMs;
  const StreamEnd({
    required super.conversationId,
    this.costUsd,
    this.durationMs,
  });
}

class StatusUpdate extends StreamEvent {
  final String statusText;
  const StatusUpdate({
    required super.conversationId,
    required this.statusText,
  });
}

class StreamError extends StreamEvent {
  final String error;
  const StreamError({required super.conversationId, required this.error});
}
