import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo.dart';
import '../shared/marketing_chrome.dart';

class HomePageDesktop extends ConsumerWidget {
  const HomePageDesktop({super.key});

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
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Where players get discovered.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A Player builds a credible profile. A Club finds that player '
                    'through search. A Club contacts them directly — no middleman, '
                    'no noise.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: () => context.go('/register'),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Text('Get started'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => context.go('/players'),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Text('Browse players'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.badge_outlined,
                          title: 'Build a profile',
                          body:
                              'Personal info, sports stats, photos, video, achievements, '
                              'and contact details — everything a Club needs to evaluate you.',
                        ),
                      ),
                      SizedBox(width: 24),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.search_outlined,
                          title: 'Get found',
                          body:
                              'Clubs search by country, age, position, height, weight, '
                              'preferred foot, and sport — filtered to exactly who they need.',
                        ),
                      ),
                      SizedBox(width: 24),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.chat_outlined,
                          title: 'Get contacted',
                          body:
                              'WhatsApp, email, or phone — a Club reaches out directly, '
                              'the moment they find the right fit.',
                        ),
                      ),
                    ],
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
