import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../config/env.dart';

/// The store now lives on the website (sportxhup.com/store), not in the app.
/// The Store tab and any old `/store` link open it in the browser, in the
/// same language the app is showing.
Uri externalStoreUri(BuildContext context) {
  final base = Env.storeUrl.replaceAll(RegExp(r'/+$'), '');
  final english = Localizations.localeOf(context).languageCode == 'en';
  if (!english) return Uri.parse(base);
  // https://sportxhup.com/store -> https://sportxhup.com/en/store
  final uri = Uri.parse(base);
  return uri.replace(path: '/en${uri.path}');
}

Future<void> openExternalStore(BuildContext context) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = AppLocalizations.of(context);
  final opened = await launchUrl(
    externalStoreUri(context),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && l10n != null) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.genericErrorMessage)));
  }
}

/// What `/store` shows if something still navigates there (an old shared
/// link on the web build, a bookmark): a way out to the website's store
/// rather than a dead end.
class ExternalStorePage extends StatelessWidget {
  const ExternalStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              l10n.storeNavLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => openExternalStore(context),
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.storeOpenOnWebsite),
            ),
          ],
        ),
      ),
    );
  }
}
