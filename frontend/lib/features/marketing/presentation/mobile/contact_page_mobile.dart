import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../shared/contact_form.dart';
import '../shared/marketing_chrome.dart';

class ContactPageMobile extends ConsumerWidget {
  const ContactPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 24),
        actions: marketingMobileAppBarActions(context, ref),
      ),
      drawer: marketingMobileDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.contactTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.contactSubtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            const ContactForm(),
          ],
        ),
      ),
    );
  }
}
