import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../shared/marketing_chrome.dart';
import '../shared/pricing_plans.dart';

class PricingPageMobile extends ConsumerWidget {
  const PricingPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final plans = pricingPlans(l10n);
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 24),
        actions: marketingMobileAppBarActions(context, ref),
      ),
      drawer: marketingMobileDrawer(context),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        children: [
          Text(
            l10n.pricingTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pricingSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          for (final plan in plans) ...[
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
                      child: Text(l10n.homeGetStarted),
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
