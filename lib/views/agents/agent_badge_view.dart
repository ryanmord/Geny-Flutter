import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../view_models/agent_picker_view_model.dart';
import 'agent_picker_view.dart';

class AgentBadgeView extends StatelessWidget {
  const AgentBadgeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentPickerViewModel>(
      builder: (context, vm, _) {
        final agent = vm.selectedAgent;
        if (agent == null) return const SizedBox.shrink();

        final color = AgentPickerView.parseColor(agent.color);

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                agent.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
