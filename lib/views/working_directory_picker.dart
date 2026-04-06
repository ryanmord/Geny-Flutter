import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../view_models/chat_view_model.dart';

class WorkingDirectoryPicker extends StatelessWidget {
  const WorkingDirectoryPicker({super.key});

  Future<void> _pickDirectory(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose Working Directory',
    );
    if (result != null && context.mounted) {
      context.read<ChatViewModel>().setWorkingDirectory(result);
    }
  }

  void _clearDirectory(BuildContext context) {
    context.read<ChatViewModel>().setWorkingDirectory(null);
  }

  String _truncatePath(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length <= 2) return path;
    return '.../${segments.sublist(segments.length - 2).join('/')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, vm, _) {
        final path = vm.workingDirectory;

        if (path != null) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentSubtle,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.folder, size: 12, color: AppColors.accent),
                const SizedBox(width: AppSpacing.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    _truncatePath(path),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                GestureDetector(
                  onTap: () => _clearDirectory(context),
                  child: Icon(
                    AppIcons.close,
                    size: 12,
                    color: AppColors.accent.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return IconButton(
          onPressed: () => _pickDirectory(context),
          icon: const Icon(AppIcons.folder, size: 16),
          tooltip: 'Choose working directory',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        );
      },
    );
  }
}
