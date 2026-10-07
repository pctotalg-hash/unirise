import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/stitch_theme.dart';
import '../../core/widgets/radial_menu.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const Duration _radialMenuLongPressDuration = Duration(milliseconds: 1112);
  static const double _movementThreshold = 12.0;

  List<PostModel> _posts = [];
  bool _isLoading = true;
  String _selectedCategory = 'Mixed Feed';

  // Radial Menu Gesture Tracking
  Offset? _touchPosition;
  Timer? _longPressTimer;
  Timer? _progressIndicatorTimer;
  bool _isLongPressActive = false;
  bool _showTouchIndicator = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _cancelGestureTimers();
    super.dispose();
  }

  void _cancelGestureTimers() {
    _longPressTimer?.cancel();
    _progressIndicatorTimer?.cancel();
    _longPressTimer = null;
    _progressIndicatorTimer = null;
    if (_showTouchIndicator) {
      setState(() {
        _showTouchIndicator = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await PostService.getPosts(category: _selectedCategory);
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _cancelGestureTimers();
    final pos = event.position;
    _touchPosition = pos;

    // Subtle touch indicator at 800ms
    _progressIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && _touchPosition != null) {
        setState(() {
          _showTouchIndicator = true;
        });
      }
    });

    // Exact 1.112 second (1112 ms) Long-Press Timer Trigger
    _longPressTimer = Timer(_radialMenuLongPressDuration, () {
      if (mounted && _touchPosition != null) {
        setState(() {
          _isLongPressActive = true;
          _showTouchIndicator = false;
        });
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_touchPosition != null) {
      final distance = (event.position - _touchPosition!).distance;
      if (distance > _movementThreshold) {
        // Finger moved beyond 12px threshold -> cancel long press
        _cancelGestureTimers();
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isLongPressActive) {
      _cancelGestureTimers();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _cancelGestureTimers();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _isLongPressActive = false;
      _touchPosition = null;
    });
    _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => StitchTheme.primaryGradient.createShader(bounds),
              child: const Text(
                'UNIRISE',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.black, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: StitchTheme.primaryCyan),
            onPressed: () {
              setState(() {
                _touchPosition = const Offset(200, 350);
                _isLongPressActive = true;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Feed Content wrapped with 1.112s Long-Press Pointer Listener
          Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: Column(
              children: [
                // Active Category Filter Bar (Only shown when a category is selected)
                if (_selectedCategory != 'Mixed Feed')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: StitchTheme.surface,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.filter_alt_rounded, color: StitchTheme.primaryCyan, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Category: ${_selectedCategory.toUpperCase()}',
                              style: const TextStyle(color: StitchTheme.primaryCyan, fontWeight: FontWeight.extrabold, fontSize: 11),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _onCategorySelected('Mixed Feed'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.redAccent),
                            ),
                            child: const Text(
                              'CLEAR FILTER',
                              style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPosts,
                    color: StitchTheme.primaryCyan,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: StitchTheme.primaryCyan))
                        : _posts.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                itemCount: _posts.length,
                                itemBuilder: (context, index) {
                                  return _buildPostCard(_posts[index]);
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),

          // 800ms - 1112ms Touch Indicator Progress Ring
          if (_showTouchIndicator && _touchPosition != null)
            Positioned(
              left: _touchPosition!.dx - 30,
              top: _touchPosition!.dy - 30,
              child: IgnorePointer(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: StitchTheme.primaryCyan, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: StitchTheme.primaryCyan.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                ),
              ),
            ),

          // 1.112 Second Long Press Radial Menu Overlay
          if (_isLongPressActive && _touchPosition != null)
            RadialMenuOverlay(
              touchPosition: _touchPosition!,
              onCategorySelected: _onCategorySelected,
              onDismiss: () => setState(() => _isLongPressActive = false),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: StitchTheme.primaryCyan,
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (res == true) _loadPosts();
        },
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    final hasImage = post.media.isNotEmpty;
    final isOpportunity = post.category == 'Hackathons' || post.category == 'Internships' || post.category == 'Opportunities';
    final previewCaption = post.content.length > 120 ? '${post.content.substring(0, 120)}...' : post.content;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => PostDetailScreen(postId: post.id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      onDoubleTap: () async {
        await PostService.likePost(post.id);
        _loadPosts();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: StitchTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: StitchTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Author Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(post.author?.profilePhoto ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.author?.name ?? 'Campus User',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                            if (post.author?.isVerified == true) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: StitchTheme.badgeBlue, size: 16),
                            ]
                          ],
                        ),
                        Text(
                          post.author?.verifiedBadge ?? post.author?.department ?? 'Student',
                          style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: StitchTheme.primaryCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: StitchTheme.primaryCyan.withOpacity(0.4)),
                    ),
                    child: Text(
                      post.category.toUpperCase(),
                      style: const TextStyle(color: StitchTheme.primaryCyan, fontSize: 10, fontWeight: FontWeight.extrabold),
                    ),
                  ),
                ],
              ),
            ),

            // Post Preview Main Image (First image only)
            if (hasImage)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    post.media.first,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

            // Content Body Preview
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.title.isNotEmpty)
                    Text(
                      post.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (post.title.isNotEmpty) const SizedBox(height: 6),
                  Text(
                    previewCaption,
                    style: const TextStyle(fontSize: 13, color: StitchTheme.textPrimary, height: 1.4),
                  ),
                  const SizedBox(height: 8),

                  if (post.hashtags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: post.hashtags.map((h) {
                        return Text(
                          h,
                          style: const TextStyle(color: StitchTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.w600),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            // Engagement Footer Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: StitchTheme.surface,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      post.likes.contains(post.author?.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: post.likes.contains(post.author?.id) ? Colors.redAccent : StitchTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () async {
                      await PostService.likePost(post.id);
                      _loadPosts();
                    },
                  ),
                  Text('${post.likes.length}', style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 12)),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: StitchTheme.textSecondary, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
                      );
                    },
                  ),
                  Text('${post.comments.length}', style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 12)),
                  const Spacer(),
                  if (isOpportunity && post.applyUrl != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening Link: ${post.applyUrl}')),
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('APPLY NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.extrabold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: StitchTheme.primaryCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dynamic_feed_rounded, color: StitchTheme.textMuted, size: 60),
          const SizedBox(height: 16),
          Text(
            'No posts in $_selectedCategory',
            style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
