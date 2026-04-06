import 'package:json_annotation/json_annotation.dart';

part 'agent.g.dart';

@JsonSerializable()
class Agent {
  final String id;
  final String name;
  final String description;
  final String? model;
  final String? color;

  Agent({
    required this.id,
    required this.name,
    required this.description,
    this.model,
    this.color,
  });

  factory Agent.fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);

  Map<String, dynamic> toJson() => _$AgentToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Agent && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
