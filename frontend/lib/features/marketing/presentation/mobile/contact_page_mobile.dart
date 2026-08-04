import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_logo.dart';
import '../shared/contact_form.dart';
import '../shared/marketing_chrome.dart';

class ContactPageMobile extends ConsumerWidget {
  const ContactPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 24),
        actions: [
          IconButton(
            tooltip: 'Toggle dark mode',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(themeModeToggleIcon(themeMode)),
          ),
        ],
      ),
      drawer: marketingMobileDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Contact us',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Questions, feedback, or partnership inquiries — send us a message.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const ContactForm(),
          ],
        ),
      ),
    );
  }
}
