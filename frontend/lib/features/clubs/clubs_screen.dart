import 'package:flutter/material.dart';
import '../../core/theme/stitch_theme.dart';
import '../../models/club_model.dart';
import '../../services/club_service.dart';
import 'club_detail_screen.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({Key? key}) : super(key: key);

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  List<ClubModel> _clubs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    try {
      final clubs = await ClubService.getClubs(isVerified: true);
      if (mounted) {
        setState(() {
          _clubs = clubs;
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
        title: const Text('Official College Clubs', style: TextStyle(fontWeight: FontWeight.black)),
        backgroundColor: StitchTheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: StitchTheme.primaryCyan))
          : RefreshIndicator(
              onRefresh: _loadClubs,
              color: StitchTheme.primaryCyan,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.verified_rounded, color: StitchTheme.badgeBlue, size: 20),
                        SizedBox(width: 6),
                        Text('College-Verified Official Societies', style: TextStyle(color: StitchTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Large Rectangular Horizontal Club Slides
                    SizedBox(
                      height: 220,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.88),
                        itemCount: _clubs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _buildRectangularClubSlide(_clubs[index]),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'All Campus Societies Directory',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    // Vertical Directory List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _clubs.length,
                      itemBuilder: (context, index) {
                        final club = _clubs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: StitchTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: StitchTheme.cardBorder),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage(club.logo),
                            ),
                            title: Row(
                              children: [
                                Text(club.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, color: StitchTheme.badgeBlue, size: 14),
                              ],
                            ),
                            subtitle: Text(club.tagline, style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: StitchTheme.primaryCyan),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: club.id)),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRectangularClubSlide(ClubModel club) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: club.id)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: StitchTheme.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: StitchTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image + Overlapping Logo
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Image.network(
                    club.coverImage,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: StitchTheme.badgeBlue),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: StitchTheme.badgeBlue, size: 12),
                        SizedBox(width: 4),
                        Text('Official', style: TextStyle(color: StitchTheme.badgeBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: -18,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: StitchTheme.cardBg, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(club.logo),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        club.name,
                        style: const TextStyle(fontWeight: FontWeight.black, fontSize: 16, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: StitchTheme.primaryCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          club.category,
                          style: const TextStyle(color: StitchTheme.primaryCyan, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    club.tagline,
                    style: const TextStyle(color: StitchTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${club.memberCount} Members', style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 11)),
                      const Text('Tap for details →', style: TextStyle(color: StitchTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
