import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class NewConversationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const NewConversationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(AppIcons.add, size: 16),
        label: const Text('New Conversation'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          backgroundColor: AppColors.accentSubtle,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }
}
