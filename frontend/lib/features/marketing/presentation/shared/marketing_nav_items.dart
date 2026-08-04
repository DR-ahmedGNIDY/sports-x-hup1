/// The public marketing site's nav — a plain data list, not a widget: each
/// of Home/About/Pricing/Contact lays out its own AppBar/Drawer completely
/// independently (Desktop horizontal nav vs. Mobile drawer), this just
/// avoids repeating the same four (label, path) pairs in eight files.
class MarketingNavItem {
  const MarketingNavItem(this.label, this.path);

  final String label;
  final String path;
}

const marketingNavItems = [
  MarketingNavItem('Home', '/home'),
  MarketingNavItem('Players', '/players'),
  MarketingNavItem('Clubs', '/clubs'),
  MarketingNavItem('About', '/about'),
  MarketingNavItem('Pricing', '/pricing'),
  MarketingNavItem('Contact', '/contact'),
];
