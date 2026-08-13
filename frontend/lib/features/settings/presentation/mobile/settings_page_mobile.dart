import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/backend_status_indicator.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/session_controller.dart';
import '../shared/change_email_form.dart';
import '../shared/change_password_form.dart';

class SettingsPageMobile extends ConsumerWidget {
  const SettingsPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dashboardAccountSettings, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text('Signed in as ${session.user?.email ?? ''}'),
            const SizedBox(height: 24),
            const ChangeEmailForm(),
            const SizedBox(height: 32),
            const ChangePasswordForm(),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Log out'),
            ),
            const SizedBox(height: 24),
            const Center(child: BackendStatusIndicator()),
          ],
        ),
      ),
    );
  }
}
