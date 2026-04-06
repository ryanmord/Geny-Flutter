import 'package:json_annotation/json_annotation.dart';

part 'integration.g.dart';

@JsonSerializable()
class IntegrationStatus {
  final String status;

  const IntegrationStatus({required this.status});

  bool get isConnected => status == 'connected';

  factory IntegrationStatus.fromJson(Map<String, dynamic> json) =>
      _$IntegrationStatusFromJson(json);

  Map<String, dynamic> toJson() => _$IntegrationStatusToJson(this);
}

@JsonSerializable()
class IntegrationsResponse {
  final IntegrationStatus figma;
  final IntegrationStatus jira;
  final IntegrationStatus anthropic;

  const IntegrationsResponse({
    required this.figma,
    required this.jira,
    required this.anthropic,
  });

  factory IntegrationsResponse.fromJson(Map<String, dynamic> json) =>
      _$IntegrationsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$IntegrationsResponseToJson(this);
}

@JsonSerializable()
class ClaudeAuthInfo {
  final bool loggedIn;
  final String? email;
  final String? orgName;
  final String? subscriptionType;

  const ClaudeAuthInfo({
    required this.loggedIn,
    this.email,
    this.orgName,
    this.subscriptionType,
  });

  factory ClaudeAuthInfo.fromJson(Map<String, dynamic> json) =>
      _$ClaudeAuthInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ClaudeAuthInfoToJson(this);
}
