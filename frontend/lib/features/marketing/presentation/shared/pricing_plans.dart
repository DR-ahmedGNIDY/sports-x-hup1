import '../../../../l10n/generated/app_localizations.dart';

/// Static content, not state — Pricing is roadmap-explicit "informational
/// only, no billing integration," so this is just display data shared by
/// the Desktop/Mobile pricing pages, not a shared widget/layout decision.
class PricingPlan {
  const PricingPlan({required this.name, required this.price, required this.features});

  final String name;
  final String price;
  final List<String> features;
}

/// A function, not a const list, because the copy is localized.
List<PricingPlan> pricingPlans(AppLocalizations l10n) => [
  PricingPlan(
    name: l10n.rolePlayer,
    price: l10n.pricingFree,
    features: [
      l10n.pricingPlayerFeature1,
      l10n.pricingPlayerFeature2,
      l10n.pricingPlayerFeature3,
      l10n.pricingPlayerFeature4,
    ],
  ),
  PricingPlan(
    name: l10n.roleClub,
    price: l10n.pricingFree,
    features: [
      l10n.pricingClubFeature1,
      l10n.pricingClubFeature2,
      l10n.pricingClubFeature3,
      l10n.pricingClubFeature4,
    ],
  ),
];
