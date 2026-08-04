import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo.dart';
import '../shared/marketing_chrome.dart';
import '../shared/pricing_plans.dart';

class PricingPageDesktop extends ConsumerWidget {
  const PricingPageDesktop({super.key});

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
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              child: Column(
                children: [
                  Text(
                    'Pricing',
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sport X Hub is free to join during launch.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 48),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final plan in pricingPlans) ...[
                        Expanded(child: _PricingCard(plan: plan)),
                        if (plan != pricingPlans.last) const SizedBox(width: 24),
                      ],
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

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.plan});

  final PricingPlan plan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
              child: const Text('Get started'),
            ),
          ],
        ),
      ),
    );
  }
}
