import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/subscription_plan.dart';
import 'user_directory_service.dart';

/// Wraps Google Play Billing. Products (pro_monthly, pro_annual, pro_2year)
/// must be created in Play Console -> Monetize -> Products -> Subscriptions
/// first, or purchases will fail with a "product not found" error.
class SubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final UserDirectoryService _userDirectory = UserDirectoryService();
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<Map<String, ProductDetails>> loadProducts() async {
    final ids = SubscriptionPlan.all.map((p) => p.productId).toSet();
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      throw Exception('Could not load plans: ${response.error!.message}');
    }
    return {for (final p in response.productDetails) p.id: p};
  }

  /// Starts listening for purchase updates. Call once (e.g. in main() or the
  /// subscription screen's initState) and keep it alive for the app's session.
  void startListening({
    required String uid,
    required void Function(SubscriptionPlan plan) onPurchaseSuccess,
    required void Function(String error) onPurchaseError,
  }) {
    _subscription = _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.pending) continue;

        if (purchase.status == PurchaseStatus.error) {
          onPurchaseError(purchase.error?.message ?? 'Purchase failed');
        } else if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          final plan = SubscriptionPlan.all.firstWhere(
            (p) => p.productId == purchase.productID,
            orElse: () => SubscriptionPlan.all.first,
          );
          final expiry = _calculateExpiry(plan);
          await _userDirectory.setProStatus(
            uid: uid,
            isPro: true,
            expiryDate: expiry,
            planId: plan.productId,
          );
          onPurchaseSuccess(plan);
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    });
  }

  DateTime _calculateExpiry(SubscriptionPlan plan) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + plan.monthsCovered, now.day);
  }

  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
