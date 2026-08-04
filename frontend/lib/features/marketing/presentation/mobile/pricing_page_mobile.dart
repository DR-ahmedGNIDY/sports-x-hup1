import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/app_logo.dart';
import '../shared/marketing_chrome.dart';
import '../shared/pricing_plans.dart';

class PricingPageMobile extends ConsumerWidget {
  const PricingPageMobile({super.key});

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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        children: [
          Text(
            'Pricing',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Sport X Hub is free to join during launch.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          for (final plan in pricingPlans) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      plan.price,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: colorScheme.primary),
                    ),
                    const SizedBox(height: 12),
                    for (final feature in plan.features)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.check, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(child: Text(feature)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Get started'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
