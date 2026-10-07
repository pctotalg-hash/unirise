import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/stitch_theme.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../clubs/club_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  List<PostModel> _userPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final targetId = widget.userId ?? auth.currentUser?.id;

    if (targetId == null) return;

    try {
      final user = await UserService.getUserById(targetId);
      final posts = await UserService.getUserPosts(targetId);
      if (mounted) {
        setState(() {
          _user = user;
          _userPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isSelf = widget.userId == null || widget.userId == auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('USER PROFILE'),
        actions: [
          if (isSelf)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onPressed: () => auth.logout(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: StitchTheme.primaryCyan))
          : _user == null
              ? const Center(child: Text('User profile not found'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Cover Photo
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Image.network(
                            _user!.coverPhoto,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),

                          // Top Right Stats (Connections & Posts)
                          Positioned(
                            right: 20,
                            bottom: 12,
                            child: Row(
                              children: [
                                _statItem('${_user!.connectionsCount}+', 'Connections'),
                                const SizedBox(width: 20),
                                _statItem('${_userPosts.length}', 'Posts'),
                              ],
                            ),
                          ),

                          // Avatar Overlapping Bottom Left
                          Positioned(
                            left: 20,
                            bottom: -35,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: StitchTheme.background, width: 4),
                              ),
                              child: CircleAvatar(
                                radius: 42,
                                backgroundImage: NetworkImage(_user!.profilePhoto),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 45),

                      // User Name & Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user!.name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_user!.year} ${_user!.department}',
                              style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 14),

                            // REQUIREMENT: VERIFIED CLUB POSITION BADGE LINK!
                            if (_user!.verifiedBadge != null)
                              InkWell(
                                onTap: () {
                                  if (_user!.verifiedClubId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: _user!.verifiedClubId!)),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: StitchTheme.cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: StitchTheme.badgeBlue, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: StitchTheme.badgeBlue.withOpacity(0.3),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.verified_rounded, color: StitchTheme.badgeBlue, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        _user!.verifiedBadge!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.verified_rounded, color: StitchTheme.badgeBlue, size: 20),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 20),

                            // About Section
                            const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 6),
                            Text(
                              _user!.bio,
                              style: const TextStyle(color: StitchTheme.textPrimary, fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 20),

                            // Skills Section
                            if (_user!.skills.isNotEmpty) ...[
                              const Text('Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _user!.skills.map((skill) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: StitchTheme.cardBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: StitchTheme.cardBorder),
                                    ),
                                    child: Text(skill, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Achievements Section
                            if (_user!.achievements.isNotEmpty) ...[
                              const Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 8),
                              ..._user!.achievements.map((ach) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(ach, style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 14)),
                                );
                              }).toList(),
                              const SizedBox(height: 20),
                            ],

                            // Post History
                            const Text('Post History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 10),
                            ..._userPosts.map((post) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: StitchTheme.cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: StitchTheme.cardBorder),
                                ),
                                child: Text(
                                  post.title.isNotEmpty ? post.title : post.content,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 11, color: StitchTheme.textSecondary)),
      ],
    );
  }
}
