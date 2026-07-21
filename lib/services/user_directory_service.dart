import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore schema (collection: users, doc id = Firebase Auth UID):
/// {
///   email, createdAt, lastSeenAt, loginCount,
///   isPro, proExpiryDate, activePlanId,
///   referralCode, referredByCode, referralCount
/// }
///
/// This collection is what both the referral system and the admin
/// dashboard read from - it's the single source of truth for user state,
/// separate from the local per-device SQLite folder data.
class UserDirectoryService {
  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  String _referralCodeFor(String uid) => uid.substring(0, 8).toUpperCase();

  /// Call once right after signup/login succeeds.
  /// Creates the Firestore profile on first login, otherwise just bumps lastSeen/loginCount.
  Future<void> recordLogin(User user, {String? referredByCode}) async {
    final docRef = _users.doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'loginCount': 1,
        'isPro': false,
        'proExpiryDate': null,
        'activePlanId': null,
        'referralCode': _referralCodeFor(user.uid),
        'referredByCode': referredByCode,
        'referralCount': 0,
      });
    } else {
      await docRef.update({
        'lastSeenAt': FieldValue.serverTimestamp(),
        'loginCount': FieldValue.increment(1),
      });
    }
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile(String uid) {
    return _users.doc(uid).snapshots();
  }

  Future<void> setProStatus({
    required String uid,
    required bool isPro,
    DateTime? expiryDate,
    String? planId,
  }) async {
    await _users.doc(uid).update({
      'isPro': isPro,
      'proExpiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
      'activePlanId': planId,
    });
  }

  // ---------- Admin dashboard queries ----------

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllUsers() async {
    final snapshot = await _users.orderBy('createdAt', descending: true).get();
    return snapshot.docs;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllUsers() {
    return _users.orderBy('lastSeenAt', descending: true).snapshots();
  }

  Future<AdminStats> getStats() async {
    final all = await _users.get();
    final docs = all.docs;
    final totalUsers = docs.length;
    final proUsers = docs.where((d) => d.data()['isPro'] == true).length;
    final totalReferrals = docs.fold<int>(
      0,
      (sum, d) => sum + ((d.data()['referralCount'] as int?) ?? 0),
    );
    final totalLogins = docs.fold<int>(
      0,
      (sum, d) => sum + ((d.data()['loginCount'] as int?) ?? 0),
    );

    final now = DateTime.now();
    final activeToday = docs.where((d) {
      final ts = d.data()['lastSeenAt'] as Timestamp?;
      if (ts == null) return false;
      final lastSeen = ts.toDate();
      return now.difference(lastSeen).inHours < 24;
    }).length;

    return AdminStats(
      totalUsers: totalUsers,
      proUsers: proUsers,
      freeUsers: totalUsers - proUsers,
      totalReferrals: totalReferrals,
      totalVisits: totalLogins,
      activeToday: activeToday,
    );
  }
}

class AdminStats {
  final int totalUsers;
  final int proUsers;
  final int freeUsers;
  final int totalReferrals;
  final int totalVisits;
  final int activeToday;

  AdminStats({
    required this.totalUsers,
    required this.proUsers,
    required this.freeUsers,
    required this.totalReferrals,
    required this.totalVisits,
    required this.activeToday,
  });
}
