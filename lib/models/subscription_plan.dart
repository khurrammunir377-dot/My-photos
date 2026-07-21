/// The three subscription tiers. usdPrice is the source of truth -
/// Play Billing will show the user's actual localized price automatically
/// once these are configured as products in Google Play Console; the
/// values here are used for our own in-app price comparison display.
enum PlanPeriod { monthly, annual, twoYear }

class SubscriptionPlan {
  final PlanPeriod period;
  final String productId; // must match the Product ID created in Play Console
  final String label;
  final double usdPrice;
  final String? badge;

  const SubscriptionPlan({
    required this.period,
    required this.productId,
    required this.label,
    required this.usdPrice,
    this.badge,
  });

  static const List<SubscriptionPlan> all = [
    SubscriptionPlan(
      period: PlanPeriod.monthly,
      productId: 'pro_monthly',
      label: 'Monthly',
      usdPrice: 1.0,
    ),
    SubscriptionPlan(
      period: PlanPeriod.annual,
      productId: 'pro_annual',
      label: 'Annual',
      usdPrice: 10.0,
      badge: 'Save 17%',
    ),
    SubscriptionPlan(
      period: PlanPeriod.twoYear,
      productId: 'pro_2year',
      label: '2 Years',
      usdPrice: 15.0,
      badge: 'Best Value',
    ),
  ];

  /// Roughly how many months of Pro this plan covers - used for referral-bonus math.
  int get monthsCovered {
    switch (period) {
      case PlanPeriod.monthly:
        return 1;
      case PlanPeriod.annual:
        return 12;
      case PlanPeriod.twoYear:
        return 24;
    }
  }
}
