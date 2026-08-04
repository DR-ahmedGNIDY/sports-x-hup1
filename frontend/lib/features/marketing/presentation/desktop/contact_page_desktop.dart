import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_logo.dart';
import '../shared/contact_form.dart';
import '../shared/marketing_chrome.dart';

class ContactPageDesktop extends ConsumerWidget {
  const ContactPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 28),
        actions: marketingDesktopNavActions(context, ref),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Contact us',
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Questions, feedback, or partnership inquiries — send us a message.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  const ContactForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
