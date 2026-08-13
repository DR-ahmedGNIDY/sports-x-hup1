import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_logo.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../shared/marketing_chrome.dart';
import '../shared/marketing_header_band.dart';

class AboutPageDesktop extends ConsumerWidget {
  const AboutPageDesktop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
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
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
                    child: Text(
                      l10n.aboutTitle,
                      style: Theme.of(
                        context,
                      ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aboutBody1,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.aboutBody2,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
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
