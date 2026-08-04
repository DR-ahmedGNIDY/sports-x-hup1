import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_logo.dart';
import '../shared/marketing_chrome.dart';

class HomePageMobile extends ConsumerWidget {
  const HomePageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
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
              'Where players get discovered.',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'A Player builds a credible profile. A Club finds that player '
              'through search. A Club contacts them directly.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/register'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Get started'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/players'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Browse players'),
              ),
            ),
            const SizedBox(height: 40),
            const _FeatureTile(
              icon: Icons.badge_outlined,
              title: 'Build a profile',
              body: 'Everything a Club needs to evaluate you.',
            ),
            const SizedBox(height: 16),
            const _FeatureTile(
              icon: Icons.search_outlined,
              title: 'Get found',
              body: 'Clubs search by exactly who they need.',
            ),
            const SizedBox(height: 16),
            const _FeatureTile(
              icon: Icons.chat_outlined,
              title: 'Get contacted',
              body: 'WhatsApp, email, or phone — direct.',
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
