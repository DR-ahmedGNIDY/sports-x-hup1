import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_logo.dart';
import '../shared/marketing_chrome.dart';

class AboutPageDesktop extends ConsumerWidget {
  const AboutPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 28),
        actions: marketingDesktopNavActions(context, ref),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Sport X Hub',
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sport X Hub is a professional sports talent marketplace connecting '
                    'Players and Clubs. Our platform exists to validate one loop: a Player '
                    'builds a credible profile, a Club finds that player through search, '
                    'and a Club contacts them directly.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No noise, no middleman, no bloated feature set — just the fastest '
                    'path from a real profile to a real conversation.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
