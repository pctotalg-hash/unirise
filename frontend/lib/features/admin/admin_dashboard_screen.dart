import 'package:flutter/material.dart';
import '../../core/theme/stitch_theme.dart';
import '../../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await AdminService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('College Dashboard', style: TextStyle(fontWeight: FontWeight.black, letterSpacing: 0.5)),
        backgroundColor: StitchTheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, color: Colors.amber, size: 28),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('UNIRISE COLLEGE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.black, color: Colors.amber)),
                          Text('Official College Administration Platform', style: TextStyle(fontSize: 12, color: StitchTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Platform Metrics Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _statCard('Total Students', '${_stats?["totalStudents"] ?? 0}', Icons.school_rounded, Colors.amber),
                      _statCard('Official Clubs', '${_stats?["totalClubs"] ?? 0}', Icons.groups_rounded, StitchTheme.primaryCyan),
                      _statCard('Campus Posts', '${_stats?["totalPosts"] ?? 0}', Icons.article_rounded, StitchTheme.secondaryPurple),
                      _statCard('Campus Events', '${_stats?["totalEvents"] ?? 0}', Icons.event_rounded, Colors.greenAccent),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('College Controls & Verifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  ListTile(
                    tileColor: StitchTheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    leading: const Icon(Icons.verified_user_rounded, color: Colors.amber),
                    title: const Text('Student Account Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Manage verified student checkmark badges', style: TextStyle(color: StitchTheme.textSecondary, fontSize: 12)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student account verified by College Authority.')));
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    tileColor: StitchTheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    leading: const Icon(Icons.swap_horiz_rounded, color: StitchTheme.primaryCyan),
                    title: const Text('Club Leadership & Position Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Assign & transfer core team badges', style: TextStyle(color: StitchTheme.textSecondary, fontSize: 12)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Position transfer control active.')));
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StitchTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StitchTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
