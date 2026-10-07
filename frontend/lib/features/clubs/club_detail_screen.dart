import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/stitch_theme.dart';
import '../../models/club_model.dart';
import '../../models/position_model.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/club_service.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../profile/profile_screen.dart';
import '../feed/post_detail_screen.dart';

class ClubDetailScreen extends StatefulWidget {
  final String clubId;

  const ClubDetailScreen({Key? key, required this.clubId}) : super(key: key);

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  ClubModel? _club;
  List<PositionModel> _coreTeam = [];
  List<PostModel> _clubPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubData();
  }

  Future<void> _loadClubData() async {
    try {
      final club = await ClubService.getClubById(widget.clubId);
      final team = await ClubService.getClubCoreTeam(widget.clubId);
      final posts = await ClubService.getClubPosts(widget.clubId);
      if (mounted) {
        setState(() {
          _club = club;
          _coreTeam = team;
          _clubPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTransferDialog(PositionModel pos) async {
    List<UserModel> candidates = [];
    try {
      candidates = await AdminService.getAdminUsers();
    } catch (_) {}

    UserModel? selectedUser;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: StitchTheme.surface,
            title: Text('Transfer Position: ${pos.positionName}', style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Currently held by: ${pos.user?.name ?? "Vacant"}',
                  style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserModel>(
                  dropdownColor: StitchTheme.cardBg,
                  decoration: const InputDecoration(labelText: 'Select New Candidate'),
                  items: candidates.map((u) {
                    return DropdownMenuItem(value: u, child: Text(u.name, style: const TextStyle(color: Colors.white)));
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedUser = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () => Navigator.pop(ctx),
              ),
              ElevatedButton(
                child: const Text('CONFIRM TRANSFER'),
                onPressed: () async {
                  if (selectedUser == null) return;
                  try {
                    await ClubService.transferPosition(_club!.id, pos.id, selectedUser!.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Position transferred to ${selectedUser!.name}')),
                    );
                    _loadClubData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final userRole = (auth.currentUser?.role ?? '').toLowerCase();
    final canManage = userRole == 'admin' || auth.currentUser?.id == _club?.coordinator?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_club?.name ?? 'Club Profile', style: const TextStyle(fontWeight: FontWeight.black)),
        backgroundColor: StitchTheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: StitchTheme.primaryCyan))
          : _club == null
              ? const Center(child: Text('Club not found'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. CLUB HEADER BANNER
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Image.network(
                            _club!.coverImage,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            left: 20,
                            bottom: -32,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: StitchTheme.background, width: 4),
                              ),
                              child: CircleAvatar(
                                radius: 38,
                                backgroundImage: NetworkImage(_club!.logo),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 44),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _club!.name,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.black, color: Colors.white),
                                ),
                                if (_club!.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded, color: StitchTheme.badgeBlue, size: 22),
                                ],
                              ],
                            ),
                            Text(_club!.tagline, style: const TextStyle(color: StitchTheme.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 14),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Club Chat...')));
                                    },
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                    label: const Text('MESSAGE', style: TextStyle(fontWeight: FontWeight.black, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: StitchTheme.primaryCyan,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joined ${_club!.name}')));
                                    },
                                    icon: const Icon(Icons.check_rounded, size: 16),
                                    label: const Text('JOINED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: StitchTheme.cardBorder),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                if (canManage) ...[
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Manage Club Panel for ${_club!.name}')));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('MANAGE', style: TextStyle(fontWeight: FontWeight.black, fontSize: 11)),
                                  ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 24),

                            // 2. ABOUT CLUB SECTION
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: StitchTheme.cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: StitchTheme.cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ABOUT CLUB', style: TextStyle(fontSize: 14, fontWeight: FontWeight.black, color: StitchTheme.primaryCyan)),
                                  const SizedBox(height: 8),
                                  Text(
                                    _club!.description,
                                    style: const TextStyle(color: StitchTheme.textPrimary, fontSize: 13, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 3. CORE TEAM SECTION
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('OFFICIAL CORE TEAM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.black, color: Colors.white)),
                                Text('Verified Roles', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._coreTeam.map((pos) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: StitchTheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: StitchTheme.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (pos.user != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => ProfileScreen(userId: pos.user!.id)),
                                          );
                                        }
                                      },
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundImage: NetworkImage(pos.user?.profilePhoto ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                pos.user?.name ?? 'Leader',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.verified_rounded, color: StitchTheme.badgeBlue, size: 14),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.amber),
                                            ),
                                            child: Text(
                                              '${pos.positionName} ✓',
                                              style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (canManage)
                                      IconButton(
                                        icon: const Icon(Icons.swap_horiz_rounded, color: StitchTheme.primaryCyan),
                                        onPressed: () => _showTransferDialog(pos),
                                        tooltip: 'Transfer Position',
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 24),

                            // 4. CLUB MEMBERS SECTION
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('CLUB MEMBERS (${_club!.members.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.black, color: Colors.white)),
                                TextButton(
                                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viewing all club members...'))),
                                  child: const Text('View All', style: TextStyle(color: StitchTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 70,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _club!.members.length,
                                itemBuilder: (context, idx) {
                                  final m = _club!.members[idx];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage: NetworkImage(m.profilePhoto),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 5. CLUB POSTS SECTION
                            const Text('CLUB POSTS & ANNOUNCEMENTS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.black, color: Colors.white)),
                            const SizedBox(height: 12),

                            ..._clubPosts.map((p) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PostDetailScreen(postId: p.id)),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: StitchTheme.cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: StitchTheme.cardBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(p.title.isNotEmpty ? p.title : 'Club Update', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: StitchTheme.primaryCyan.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(p.category, style: const TextStyle(color: StitchTheme.primaryCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        p.content.length > 100 ? '${p.content.substring(0, 100)}...' : p.content,
                                        style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Tap to view full post →', style: TextStyle(color: StitchTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
