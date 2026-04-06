import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../view_models/settings_view_model.dart';
import 'integration_card.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _figmaTokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SettingsViewModel>().loadIntegrations();
  }

  @override
  void dispose() {
    _figmaTokenController.dispose();
    context.read<SettingsViewModel>().cancelPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: Consumer<SettingsViewModel>(
                builder: (context, vm, _) {
                  if (vm.isLoading && vm.integrations == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xxxl),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      children: [
                        if (vm.error != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.lg,
                            ),
                            child: _buildErrorBanner(vm.error!),
                          ),
                        _buildClaudeCard(context, vm),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFigmaCard(context, vm),
                        const SizedBox(height: AppSpacing.lg),
                        _buildJiraCard(context, vm),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderForBrightness(Theme.of(context).brightness),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(AppIcons.close, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.error, size: 16, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaudeCard(BuildContext context, SettingsViewModel vm) {
    final isConnected = vm.integrations?.anthropic.isConnected ?? false;

    return IntegrationCard(
      title: 'Claude / Anthropic',
      icon: AppIcons.sparkles,
      isConnected: isConnected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isConnected && vm.claudeInfo != null) ...[
            _buildDetailRow('Email', vm.claudeInfo!.email ?? 'N/A'),
            if (vm.claudeInfo!.orgName != null)
              _buildDetailRow('Organization', vm.claudeInfo!.orgName!),
            if (vm.claudeInfo!.subscriptionType != null)
              _buildDetailRow('Plan', vm.claudeInfo!.subscriptionType!),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => _confirmDisconnect(
                context,
                'Claude',
                vm.disconnectClaude,
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Disconnect'),
            ),
          ] else ...[
            if (vm.isAuthenticatingClaude)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text('Waiting for authentication...', style: TextStyle(fontSize: 13)),
                ],
              )
            else
              ElevatedButton(
                onPressed: vm.authenticateClaude,
                child: const Text('Connect Claude'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFigmaCard(BuildContext context, SettingsViewModel vm) {
    final isConnected = vm.integrations?.figma.isConnected ?? false;

    return IntegrationCard(
      title: 'Figma',
      icon: Icons.design_services,
      isConnected: isConnected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isConnected) ...[
            const Text('Connected', style: TextStyle(fontSize: 13)),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => _confirmDisconnect(
                context,
                'Figma',
                vm.removeFigmaToken,
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Disconnect'),
            ),
          ] else ...[
            TextField(
              controller: _figmaTokenController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Paste Figma access token',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: () {
                final token = _figmaTokenController.text.trim();
                if (token.isNotEmpty) {
                  vm.setFigmaToken(token);
                  _figmaTokenController.clear();
                }
              },
              child: const Text('Connect'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJiraCard(BuildContext context, SettingsViewModel vm) {
    final isConnected = vm.integrations?.jira.isConnected ?? false;

    return IntegrationCard(
      title: 'Jira',
      icon: Icons.task_alt,
      isConnected: isConnected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isConnected) ...[
            const Text('Connected', style: TextStyle(fontSize: 13)),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => _confirmDisconnect(
                context,
                'Jira',
                vm.disconnectJira,
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Disconnect'),
            ),
          ] else ...[
            if (vm.isAuthenticatingJira)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text('Waiting for authentication...', style: TextStyle(fontSize: 13)),
                ],
              )
            else
              ElevatedButton(
                onPressed: vm.authenticateJira,
                child: const Text('Connect Jira'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDisconnect(
    BuildContext context,
    String name,
    VoidCallback onDisconnect,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect $name'),
        content: Text('Are you sure you want to disconnect $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDisconnect();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
