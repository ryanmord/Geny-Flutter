import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/agent.dart';
import '../../theme/app_theme.dart';
import '../../view_models/agent_picker_view_model.dart';

class AgentPickerView extends StatelessWidget {
  const AgentPickerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentPickerViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.agents.isEmpty) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (vm.agents.isEmpty) {
          return const SizedBox.shrink();
        }

        return PopupMenuButton<String>(
          onSelected: vm.selectAgent,
          tooltip: 'Select agent',
          offset: const Offset(0, 36),
          itemBuilder: (context) => vm.agents.map((agent) {
            return PopupMenuItem<String>(
              value: agent.id,
              child: Row(
                children: [
                  _AgentColorDot(color: parseColor(agent.color)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          agent.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (agent.description.isNotEmpty)
                          Text(
                            agent.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (agent.id == vm.selectedAgentId)
                    const Icon(AppIcons.check, size: 16, color: AppColors.accent),
                ],
              ),
            );
          }).toList(),
          child: _buildTrigger(context, vm.selectedAgent),
        );
      },
    );
  }

  Widget _buildTrigger(BuildContext context, Agent? agent) {
    if (agent == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSubtle,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AgentColorDot(color: parseColor(agent.color)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            agent.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: AppSpacing.xxs),
          const Icon(AppIcons.chevronDown, size: 14),
        ],
      ),
    );
  }

  static Color parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.accent;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return AppColors.accent;
  }
}

class _AgentColorDot extends StatelessWidget {
  final Color color;

  const _AgentColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
