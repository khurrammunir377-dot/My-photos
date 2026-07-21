import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/user_directory_service.dart';
import '../../utils/constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _userDirectory = UserDirectoryService();
  AdminStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _userDirectory.getStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Admin Dashboard', style: TextStyle(color: AppColors.textDark)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.textDark), onPressed: _loadStats),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statsGrid(),
            const SizedBox(height: 20),
            const Text('All Users', style: AppTextStyles.heading),
            const SizedBox(height: 8),
            _userList(),
          ],
        ),
      ),
    );
  }

  Widget _statsGrid() {
    final s = _stats;
    if (s == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final items = [
      ('Total Users', s.totalUsers.toString(), Icons.people, AppColors.primary),
      ('Pro Users', s.proUsers.toString(), Icons.workspace_premium, AppColors.proGold),
      ('Free Users', s.freeUsers.toString(), Icons.person_outline, AppColors.textMuted),
      ('Active Today', s.activeToday.toString(), Icons.bolt, AppColors.accent),
      ('Total Referrals', s.totalReferrals.toString(), Icons.card_giftcard, AppColors.primary),
      ('Total Visits (logins)', s.totalVisits.toString(), Icons.login, AppColors.textDark),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.$3 as IconData, color: item.$4 as Color, size: 22),
              const Spacer(),
              Text(item.$2, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(item.$1, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _userList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _userDirectory.watchAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('No users yet', style: AppTextStyles.subheading)),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final isPro = data['isPro'] == true;
            final email = (data['email'] as String?) ?? 'unknown';
            final lastSeen = (data['lastSeenAt'] as Timestamp?)?.toDate();
            final loginCount = data['loginCount'] as int? ?? 0;
            final referralCount = data['referralCount'] as int? ?? 0;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isPro ? AppColors.proGold.withOpacity(0.2) : AppColors.primary.withOpacity(0.15),
                    child: Icon(isPro ? Icons.workspace_premium : Icons.person, color: isPro ? AppColors.proGold : AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(email, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          'Logins: $loginCount \u2022 Referrals: $referralCount'
                          '${lastSeen != null ? ' \u2022 Last seen: ${_formatDate(lastSeen)}' : ''}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (isPro)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.proGold, borderRadius: BorderRadius.circular(20)),
                      child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
