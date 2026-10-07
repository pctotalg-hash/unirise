import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/stitch_theme.dart';
import '../../services/search_service.dart';
import '../clubs/club_detail_screen.dart';
import '../feed/post_detail_screen.dart';
import '../profile/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  SearchResultModel? _results;
  AISearchResultModel? _aiResults;
  bool _isLoading = false;
  String _selectedCategory = 'ALL';

  final List<String> _categories = [
    'ALL',
    'PEOPLE',
    'POSTS',
    'CLUBS',
    'EVENTS',
    'HACKATHONS',
    'INTERNSHIPS',
    'GROUPS',
    'OPPORTUNITIES'
  ];

  final List<String> _recentSearches = ['hackathon', 'coding club', 'AI internship', 'Rahul'];

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchInputChanged(String val) {
    _debounceTimer?.cancel();

    if (val.trim().isEmpty) {
      setState(() {
        _results = null;
        _aiResults = null;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(val.trim());
    });
  }

  Future<void> _executeSearch(String query) async {
    try {
      final searchRes = await SearchService.globalSearch(query, category: _selectedCategory);
      final aiRes = await SearchService.getAISuggestions(query);
      if (mounted) {
        setState(() {
          _results = searchRes;
          _aiResults = aiRes;
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
        title: const Text('Campus Search & AI Agent', style: TextStyle(fontWeight: FontWeight.black)),
        backgroundColor: StitchTheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Input Bar
            TextField(
              controller: _searchController,
              onChanged: _onSearchInputChanged,
              decoration: InputDecoration(
                hintText: 'Search students, clubs, hackathons, events...',
                prefixIcon: const Icon(Icons.search_rounded, color: StitchTheme.primaryCyan),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: StitchTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchInputChanged('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // Category Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: StitchTheme.primaryCyan,
                      backgroundColor: StitchTheme.cardBg,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected ? FontWeight.black : FontWeight.bold,
                        fontSize: 11,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                          if (_searchController.text.trim().isNotEmpty) {
                            _executeSearch(_searchController.text.trim());
                          }
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Main Dynamic Results Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: StitchTheme.primaryCyan))
                  : _searchController.text.trim().isEmpty
                      ? _buildEmptySearchState()
                      : ListView(
                          children: [
                            // 1. UNIRISE AI SEARCH AGENT CARD
                            if (_aiResults != null && _aiResults!.suggestions.isNotEmpty)
                              _buildAISearchCard(),

                            // 2. HACKATHONS
                            if (_results != null && _results!.hackathons.isNotEmpty)
                              _buildPostSection('HACKATHONS', _results!.hackathons, Icons.code_rounded, StitchTheme.primaryCyan),

                            // 3. INTERNSHIPS
                            if (_results != null && _results!.internships.isNotEmpty)
                              _buildPostSection('INTERNSHIPS', _results!.internships, Icons.work_rounded, Colors.amber),

                            // 4. CLUBS
                            if (_results != null && _results!.clubs.isNotEmpty)
                              _buildClubSection(_results!.clubs),

                            // 5. PEOPLE / USERS
                            if (_results != null && _results!.users.isNotEmpty)
                              _buildUserSection(_results!.users),

                            // 6. POSTS
                            if (_results != null && _results!.posts.isNotEmpty)
                              _buildPostSection('POSTS & UPDATES', _results!.posts, Icons.article_rounded, StitchTheme.secondaryPurple),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return ListView(
      children: [
        // Recent Searches
        Container(
          padding: const EdgeInsets.all(14),
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
                  const Text('Recent Searches', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  InkWell(
                    onTap: () => setState(() => _recentSearches.clear()),
                    child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches.map((q) {
                  return InkWell(
                    onTap: () {
                      _searchController.text = q;
                      _onSearchInputChanged(q);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: StitchTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: StitchTheme.cardBorder),
                      ),
                      child: Text(q, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Discover Campus Chips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: StitchTheme.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: StitchTheme.cardBorder),
          ),
          child: Column(
            children: [
              const Icon(Icons.explore_rounded, color: StitchTheme.primaryCyan, size: 40),
              const SizedBox(height: 8),
              const Text('Discover Your Campus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Search hackathons, AI internships, coding clubs & students', style: TextStyle(color: StitchTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _quickChip('💻 Hackathons', 'hackathon'),
                  _quickChip('🏆 Coding Club', 'coding club'),
                  _quickChip('💼 Internships', 'AI internship'),
                  _quickChip('🎓 Verified Students', 'Rahul'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickChip(String label, String query) {
    return InkWell(
      onTap: () {
        _searchController.text = query;
        _onSearchInputChanged(query);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: StitchTheme.primaryCyan.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: StitchTheme.primaryCyan.withOpacity(0.4)),
        ),
        child: Text(label, style: const TextStyle(color: StitchTheme.primaryCyan, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAISearchCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StitchTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StitchTheme.secondaryPurple, width: 2),
        boxShadow: [
          BoxShadow(
            color: StitchTheme.secondaryPurple.withOpacity(0.2),
            blurRadius: 15,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.smart_toy_rounded, color: StitchTheme.secondaryPurple, size: 20),
                  SizedBox(width: 8),
                  Text('UNIRISE AI SEARCH AGENT', style: TextStyle(color: StitchTheme.secondaryPurple, fontWeight: FontWeight.black, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: StitchTheme.secondaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _aiResults!.intent,
                  style: const TextStyle(color: StitchTheme.secondaryPurple, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._aiResults!.suggestions.map((s) {
            return InkWell(
              onTap: () {
                if (s.referenceId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PostDetailScreen(postId: s.referenceId!)),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: StitchTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: StitchTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: StitchTheme.primaryCyan, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          if (s.subtitle.isNotEmpty) Text(s.subtitle, style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 10)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: StitchTheme.secondaryPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('🤖 AI Suggested', style: TextStyle(color: StitchTheme.secondaryPurple, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildClubSection(List<ClubModel> clubs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OFFICIAL CLUBS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.black, color: StitchTheme.secondaryPurple)),
        const SizedBox(height: 8),
        ...clubs.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: StitchTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: StitchTheme.cardBorder),
              ),
              child: ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(c.logo)),
                title: Row(
                  children: [
                    Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, color: StitchTheme.badgeBlue, size: 14),
                  ],
                ),
                subtitle: Text(c.tagline, style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded, color: StitchTheme.primaryCyan),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: c.id)),
                  );
                },
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUserSection(List<UserModel> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VERIFIED PEOPLE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.black, color: Colors.greenAccent)),
        const SizedBox(height: 8),
        ...users.map((u) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: StitchTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: StitchTheme.cardBorder),
              ),
              child: ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(u.profilePhoto)),
                title: Row(
                  children: [
                    Text(u.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    if (u.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: StitchTheme.badgeBlue, size: 14),
                    ]
                  ],
                ),
                subtitle: Text('${u.department ?? "Student"} • ${u.year ?? ""}', style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded, color: StitchTheme.primaryCyan),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileScreen(userId: u.id)),
                  );
                },
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPostSection(String title, List<PostModel> posts, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.black, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ...posts.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: StitchTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: StitchTheme.cardBorder),
              ),
              child: ListTile(
                title: Text(p.title.isNotEmpty ? p.title : p.content, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(p.category, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right_rounded, color: StitchTheme.primaryCyan),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PostDetailScreen(postId: p.id)),
                  );
                },
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
