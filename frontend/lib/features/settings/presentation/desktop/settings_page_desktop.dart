import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/backend_status_indicator.dart';
import '../../../auth/application/session_controller.dart';
import '../shared/change_email_form.dart';
import '../shared/change_password_form.dart';

class SettingsPageDesktop extends ConsumerWidget {
  const SettingsPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
      ),
    );
  }
}
