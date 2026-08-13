import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/backend_status_indicator.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../shared/change_email_form.dart';
import '../shared/change_password_form.dart';

class SettingsPageDesktop extends ConsumerWidget {
  const SettingsPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.dashboardAccountSettings, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              Text('Signed in as ${session.user?.email ?? ''}'),
              const SizedBox(height: 32),
              const ChangeEmailForm(),
              const SizedBox(height: 40),
              const ChangePasswordForm(),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Log out'),
              ),
              const SizedBox(height: 32),
              const Center(child: BackendStatusIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
