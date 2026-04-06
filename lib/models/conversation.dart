import 'package:json_annotation/json_annotation.dart';

part 'conversation.g.dart';

@JsonSerializable()
class Conversation {
  final String id;
  String title;
  String agentId;
  String? sessionId;
  final String createdAt;
  String updatedAt;

  Conversation({
    required this.id,
    required this.title,
    required this.agentId,
    this.sessionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);
}

@JsonSerializable()
class ConversationDetail {
  final Conversation metadata;
  final List<StoredMessage> messages;

  ConversationDetail({
    required this.metadata,
    required this.messages,
  });

  factory ConversationDetail.fromJson(Map<String, dynamic> json) =>
      _$ConversationDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationDetailToJson(this);
}

@JsonSerializable()
class StoredMessage {
  final String id;
  final String role;
  final List<ContentBlockJson> content;
  final String timestamp;

  StoredMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory StoredMessage.fromJson(Map<String, dynamic> json) =>
      _$StoredMessageFromJson(json);

  Map<String, dynamic> toJson() => _$StoredMessageToJson(this);
}

@JsonSerializable()
class ContentBlockJson {
  final String type;
  final String? text;
  final String? language;
  final String? code;
  final String? toolName;
  final Map<String, dynamic>? input;
  final ToolResultJson? result;

  ContentBlockJson({
    required this.type,
    this.text,
    this.language,
    this.code,
    this.toolName,
    this.input,
    this.result,
  });

  factory ContentBlockJson.fromJson(Map<String, dynamic> json) =>
      _$ContentBlockJsonFromJson(json);

  Map<String, dynamic> toJson() => _$ContentBlockJsonToJson(this);
}

@JsonSerializable()
class ToolResultJson {
  final String? output;
  final String? error;

  ToolResultJson({this.output, this.error});

  factory ToolResultJson.fromJson(Map<String, dynamic> json) =>
      _$ToolResultJsonFromJson(json);

  Map<String, dynamic> toJson() => _$ToolResultJsonToJson(this);
}
