import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../shared/marketing_chrome.dart';
import '../shared/marketing_header_band.dart';
import '../shared/pricing_plans.dart';

class PricingPageDesktop extends ConsumerWidget {
  const PricingPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final plans = pricingPlans(l10n);
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 28),
        actions: marketingDesktopNavActions(context, ref),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MarketingHeaderBand(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
                    child: Column(
                      children: [
                        Text(
                          l10n.pricingTitle,
                          style: Theme.of(
                            context,
                          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.pricingSubtitle, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 48, 32, 80),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final plan in plans) ...[
                        Expanded(child: _PricingCard(plan: plan)),
                        if (plan != plans.last) const SizedBox(width: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.plan});

  final PricingPlan plan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              plan.price,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 16),
            for (final feature in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/register'),
              child: Text(l10n.homeGetStarted),
            ),
          ],
        ),
      ),
    );
  }
}
