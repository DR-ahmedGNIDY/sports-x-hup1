import '../../../../l10n/generated/app_localizations.dart';

/// The public marketing site's nav — a plain data list, not a widget: each
/// of Home/About/Pricing/Contact lays out its own AppBar/Drawer completely
/// independently (Desktop horizontal nav vs. Mobile drawer), this just
/// avoids repeating the same four (label, path) pairs in eight files.
class MarketingNavItem {
  const MarketingNavItem(this.label, this.path);

  final String label;
  final String path;
}

/// A function, not a const list, because the labels are localized —
/// evaluated fresh against whichever AppLocalizations is active.
List<MarketingNavItem> marketingNavItems(AppLocalizations l10n) => [
  MarketingNavItem(l10n.marketingNavHome, '/home'),
  MarketingNavItem(l10n.marketingNavPlayers, '/players'),
  MarketingNavItem(l10n.marketingNavClubs, '/clubs'),
  MarketingNavItem(l10n.marketingNavAbout, '/about'),
  MarketingNavItem(l10n.marketingNavPricing, '/pricing'),
  MarketingNavItem(l10n.marketingNavContact, '/contact'),
];
