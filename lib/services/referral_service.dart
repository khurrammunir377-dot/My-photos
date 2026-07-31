import 'package:cloud_firestore/cloud_firestore.dart';

/// Referral rule: refer 10 people who sign up -> referrer gets 6 months of Pro free.
///
/// IMPORTANT SECURITY NOTE: this implementation updates Firestore directly from
/// the app for simplicity in this phase. Because Firestore security rules can
/// restrict *which* fields a client may write, make sure your rules block
/// direct client writes to `isPro` / `proExpiryDate` / `referralCount` on
/// other users' documents - only allow the increment to happen via this
/// service's transaction, or better, move this logic into a Cloud Function
/// before launch so a modified APK can't fake referrals. See README.
class ReferralService {
  CollectionReference<Map<String, dynamic>> get _users => FirebaseFirestore.instance.collection('users');
  static const int referralsNeededForReward = 10;
  static const int rewardMonths = 6;

  /// Call this during signup if the new user entered someone else's referral code.
  /// Looks up the referrer by code, links the new user to them, and increments
  /// the referrer's count. Silently no-ops if the code doesn't exist (bad input).
  Future<void> applyReferralCode(String newUserUid, String referralCode) async {
    final referrerQuery =
        await _users.where('referralCode', isEqualTo: referralCode.toUpperCase()).limit(1).get();
    if (referrerQuery.docs.isEmpty) return;

    final referrerDoc = referrerQuery.docs.first;
    if (referrerDoc.id == newUserUid) return; // can't refer yourself

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final referrerRef = _users.doc(referrerDoc.id);
      final freshReferrer = await tx.get(referrerRef);
      final currentCount = (freshReferrer.data()?['referralCount'] as int?) ?? 0;
      final newCount = currentCount + 1;

      final updates = <String, dynamic>{'referralCount': newCount};

      // Grant reward every time the count crosses a multiple of 10
      if (newCount % referralsNeededForReward == 0) {
        final existingExpiry = (freshReferrer.data()?['proExpiryDate'] as Timestamp?)?.toDate();
        final base = (existingExpiry != null && existingExpiry.isAfter(DateTime.now()))
            ? existingExpiry
            : DateTime.now();
        final newExpiry = DateTime(base.year, base.month + rewardMonths, base.day);
        updates['isPro'] = true;
        updates['proExpiryDate'] = Timestamp.fromDate(newExpiry);
        updates['activePlanId'] = 'referral_reward';
      }

      tx.update(referrerRef, updates);
    });
  }

  Future<String?> getReferralCode(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data()?['referralCode'] as String?;
  }

  Future<int> getReferralCount(String uid) async {
    final doc = await _users.doc(uid).get();
    return (doc.data()?['referralCount'] as int?) ?? 0;
  }

  int referralsUntilNextReward(int currentCount) {
    final remainder = currentCount % referralsNeededForReward;
    return remainder == 0 ? referralsNeededForReward : referralsNeededForReward - remainder;
  }
}
