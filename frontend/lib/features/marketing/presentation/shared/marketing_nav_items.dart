import '../../../../l10n/generated/app_localizations.dart';

/// The public listings' nav — a plain data list, not a widget, shared by the
/// desktop header and the mobile drawer.
class MarketingNavItem {
  const MarketingNavItem(this.label, this.path);

  final String label;
  final String path;
}

/// A function, not a const list, because the labels are localized —
/// evaluated fresh against whichever AppLocalizations is active.
///
/// Home/About/Pricing/Contact moved to the website (sportxhup.com); only the
/// public listings, which still live in the app, remain.
List<MarketingNavItem> marketingNavItems(AppLocalizations l10n) => [
  MarketingNavItem(l10n.marketingNavPlayers, '/players'),
  MarketingNavItem(l10n.marketingNavClubs, '/clubs'),
];
