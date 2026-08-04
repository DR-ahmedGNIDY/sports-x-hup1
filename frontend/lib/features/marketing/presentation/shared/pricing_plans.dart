/// Static content, not state — Pricing is roadmap-explicit "informational
/// only, no billing integration," so this is just display data shared by
/// the Desktop/Mobile pricing pages, not a shared widget/layout decision.
class PricingPlan {
  const PricingPlan({required this.name, required this.price, required this.features});

  final String name;
  final String price;
  final List<String> features;
}

const pricingPlans = [
  PricingPlan(
    name: 'Player',
    price: 'Free',
    features: [
      'Full player profile with photos & video',
      'Achievements and social links',
      'Public or private visibility',
      'Direct contact from interested Clubs',
    ],
  ),
  PricingPlan(
    name: 'Club',
    price: 'Free',
    features: [
      'Search players by 7 filters',
      'Save players to a shortlist',
      'Direct WhatsApp / email / phone contact',
      'Club profile page',
    ],
  ),
];
