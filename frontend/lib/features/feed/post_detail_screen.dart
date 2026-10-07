import 'package:flutter/material.dart';
import '../../core/theme/stitch_theme.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  PostModel? _post;
  bool _isLoading = true;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  Future<void> _fetchPost() async {
    try {
      final post = await PostService.getPostById(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      await PostService.commentPost(_post!.id, _commentController.text.trim());
      _commentController.clear();
      _fetchPost();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authorName = _post?.author?.name ?? 'Campus User';
    final authorPhoto = _post?.author?.profilePhoto ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';
    final subTitle = _post?.author?.verifiedBadge ?? _post?.author?.department ?? 'Student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: StitchTheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: StitchTheme.primaryCyan))
          : _post == null
              ? const Center(child: Text('Post not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(authorPhoto),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      authorName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                    ),
                                    if (_post!.author?.isVerified == true) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded, color: StitchTheme.badgeBlue, size: 16),
                                    ],
                                  ],
                                ),
                                Text(
                                  subTitle,
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
                              _post!.category.toUpperCase(),
                              style: const TextStyle(color: StitchTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Full Post Media Images
                      if (_post!.media.isNotEmpty) ...[
                        Column(
                          children: _post!.media.map((img) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  img,
                                  width: double.infinity,
                                  height: 240,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Title & Full Content
                      if (_post!.title.isNotEmpty)
                        Text(
                          _post!.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.black, color: Colors.white, height: 1.3),
                        ),
                      if (_post!.title.isNotEmpty) const SizedBox(height: 10),
                      Text(
                        _post!.content,
                        style: const TextStyle(fontSize: 14, color: StitchTheme.textPrimary, height: 1.5),
                      ),
                      const SizedBox(height: 14),

                      // Hashtags
                      if (_post!.hashtags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _post!.hashtags.map((h) {
                            return Text(
                              h,
                              style: const TextStyle(color: StitchTheme.primaryCyan, fontSize: 13, fontWeight: FontWeight.bold),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // Category Specific Cards
                      if (_post!.category == 'Events') ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: StitchTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: StitchTheme.primaryCyan.withOpacity(0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('EVENT INFORMATION', style: TextStyle(color: StitchTheme.primaryCyan, fontWeight: FontWeight.extrabold, fontSize: 12)),
                              SizedBox(height: 8),
                              Text('Date: Upcoming Weekend', style: TextStyle(color: Colors.white, fontSize: 13)),
                              Text('Time: 10:00 AM - 04:00 PM', style: TextStyle(color: Colors.white, fontSize: 13)),
                              Text('Location: College Auditorium', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Apply Now Button
                      if (_post!.applyUrl != null) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Opening Application URL: ${_post!.applyUrl}')),
                              );
                            },
                            icon: const Icon(Icons.open_in_new_rounded, size: 20),
                            label: const Text('APPLY / REGISTER NOW', style: TextStyle(fontWeight: FontWeight.black, letterSpacing: 1.0)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: StitchTheme.primaryCyan,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const Divider(color: StitchTheme.cardBorder),
                      const SizedBox(height: 10),
                      const Text('Comments & Discussion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),

                      // Comments List
                      ..._post!.comments.map((c) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: StitchTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: StitchTheme.cardBorder),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(c.userPhoto.isNotEmpty ? c.userPhoto : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: StitchTheme.primaryCyan)),
                                      const SizedBox(height: 2),
                                      Text(c.text, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),

                      // Add Comment Box
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: 'Write a campus comment...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: StitchTheme.primaryCyan),
                            onPressed: _addComment,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
