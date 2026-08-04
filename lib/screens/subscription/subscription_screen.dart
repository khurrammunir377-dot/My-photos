import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../models/subscription_plan.dart';
import '../../services/currency_helper.dart';
import '../../services/folder_service.dart';
import '../../services/referral_service.dart';
import '../../services/subscription_service.dart';
import '../../services/user_directory_service.dart';
import '../../utils/constants.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  final _referralService = ReferralService();
  final _folderService = FolderService();

  Map<String, ProductDetails> _products = {};
  bool _loadingProducts = true;
  String? _productError;

  String _currency = 'USD';
  double _rate = 1.0;
  bool _loadingRate = true;

  String? _referralCode;
  int _referralCount = 0;
  bool _purchasing = false;

  bool _isProNow = false;

  Future<void> _toggleTestProMode() async {
    final newValue = !_isProNow;
    await _folderService.setProUser(newValue);
    if (AppConstants.kFirebaseEnabled) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await UserDirectoryService().setProStatus(
          uid: uid,
          isPro: newValue,
          expiryDate: newValue ? DateTime.now().add(const Duration(days: 30)) : null,
          planId: newValue ? 'test_mode' : null,
        );
      }
    }
    setState(() => _isProNow = newValue);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newValue ? 'Test Pro enabled for 30 days' : 'Test Pro disabled')),
      );
    }
  }

  Widget _testModeCard() {
    return Card(
      color: Colors.amber.withOpacity(0.12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science_outlined, color: Colors.orange),
                SizedBox(width: 8),
                Text('Developer Test Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Real purchases won\'t work until your app has products set up in Play Console. '
              'Use this to test Pro features (unlimited folders, etc.) on your own device in the meantime. '
              'Remove this card before publishing to Play Store.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: _toggleTestProMode,
                child: Text(_isProNow ? 'Disable Test Pro' : 'Enable Test Pro (30 days)',
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentProStatus();
    _init();
  }

  Future<void> _loadCurrentProStatus() async {
    final isPro = await _folderService.isProUser();
    if (mounted) setState(() => _isProNow = isPro);
  }

  Future<void> _init() async {
    final uid = AppConstants.kFirebaseEnabled ? FirebaseAuth.instance.currentUser?.uid : null;

    _subscriptionService.startListening(
      uid: uid ?? '',
      onPurchaseSuccess: (plan) async {
        await _folderService.setProUser(true);
        if (mounted) {
          setState(() => _purchasing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome to Pro! Your ${plan.label} plan is active.'),
              backgroundColor: AppColors.accent,
            ),
          );
          Navigator.pop(context);
        }
      },
      onPurchaseError: (error) {
        if (mounted) {
          setState(() => _purchasing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
        }
      },
    );

    await Future.wait([_loadProducts(), _loadCurrency(), _loadReferralInfo(uid)]);
  }

  Future<void> _loadProducts() async {
    try {
      final available = await _subscriptionService.isAvailable();
      if (!available) {
        setState(() {
          _productError = 'Store unavailable right now. Try again later.';
          _loadingProducts = false;
        });
        return;
      }
      final products = await _subscriptionService.loadProducts();
      setState(() {
        _products = products;
        _loadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _productError = e.toString();
        _loadingProducts = false;
      });
    }
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyHelper.getPreferredCurrency();
    final rate = await CurrencyHelper.getRate(currency);
    setState(() {
      _currency = currency;
      _rate = rate;
      _loadingRate = false;
    });
  }

  Future<void> _loadReferralInfo(String? uid) async {
    if (uid == null) return;
    final code = await _referralService.getReferralCode(uid);
    final count = await _referralService.getReferralCount(uid);
    setState(() {
      _referralCode = code;
      _referralCount = count;
    });
  }

  Future<void> _changeCurrency(String code) async {
    setState(() => _loadingRate = true);
    await CurrencyHelper.setPreferredCurrency(code);
    final rate = await CurrencyHelper.getRate(code);
    setState(() {
      _currency = code;
      _rate = rate;
      _loadingRate = false;
    });
  }

  Future<void> _buy(SubscriptionPlan plan) async {
    final product = _products[plan.productId];
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This plan is not available yet - check back soon.')),
      );
      return;
    }
    setState(() => _purchasing = true);
    await _subscriptionService.buy(product);
  }

  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Go Pro', style: TextStyle(color: AppColors.textDark)),
        actions: [_currencySelector()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Choose your plan', style: AppTextStyles.heading),
          const SizedBox(height: 6),
          const Text(
            'Unlimited folders, no watermark, priority support.',
            style: AppTextStyles.subheading,
          ),
          const SizedBox(height: 20),
          _testModeCard(),
          const SizedBox(height: 20),
          if (_productError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(_productError!, style: const TextStyle(color: AppColors.error)),
            ),
          if (_loadingProducts)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
            ...SubscriptionPlan.all.map(_planCard),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () async {
                await _subscriptionService.restorePurchases();
              },
              child: const Text('Restore purchases'),
            ),
          ),
          const SizedBox(height: 24),
          if (AppConstants.kFirebaseEnabled)
            _referralCard()
          else
            Card(
              color: Colors.grey.withOpacity(0.08),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Referral program will be available once Firebase is set up.',
                  style: AppTextStyles.subheading,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _currencySelector() {
    return PopupMenuButton<String>(
      onSelected: _changeCurrency,
      itemBuilder: (context) => CurrencyHelper.supported
          .map((c) => PopupMenuItem(value: c.code, child: Text('${c.symbol} ${c.code} - ${c.name}')))
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(_currency, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
            const Icon(Icons.arrow_drop_down, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }

  Widget _planCard(SubscriptionPlan plan) {
    final priceLabel = _loadingRate
        ? '...'
        : CurrencyHelper.formatPrice(plan.usdPrice, _currency, _rate);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: plan.badge != null ? AppColors.primary : Colors.grey.shade200, width: plan.badge != null ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(plan.badge!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(priceLabel, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  if (_currency != 'USD')
                    const Text('Billed in your local currency via Google Play', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: _purchasing ? null : () => _buy(plan),
              child: _purchasing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Choose', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _referralCard() {
    final remaining = _referralService.referralsUntilNextReward(_referralCount);
    return Card(
      color: AppColors.primary.withOpacity(0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Refer friends, get Pro free', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Invite 10 friends who sign up and you get 6 months of Pro, free. Repeats every 10 referrals.',
              style: AppTextStyles.subheading,
            ),
            const SizedBox(height: 14),
            if (_referralCode != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_referralCode!, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)),
                    Icon(Icons.copy, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Text('$_referralCount referred so far \u2022 $remaining more for your next free 6 months',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
