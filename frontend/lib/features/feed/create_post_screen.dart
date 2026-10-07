import 'package:flutter/material.dart';
import '../../core/theme/stitch_theme.dart';
import '../../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _hashtagsController = TextEditingController();
  final _applyUrlController = TextEditingController();
  String _selectedCategory = 'Student Posts';
  bool _isLoading = false;

  final List<String> _categories = [
    'Student Posts',
    'Events',
    'Hackathons',
    'Internships',
    'Clubs',
    'Announcements',
    'Opportunities'
  ];

  void _submitPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter post content')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final tags = _hashtagsController.text
          .split(' ')
          .where((t) => t.trim().isNotEmpty)
          .map((t) => t.startsWith('#') ? t : '#$t')
          .toList();

      await PostService.createPost(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        hashtags: tags,
        applyUrl: _applyUrlController.text.trim().isNotEmpty ? _applyUrlController.text.trim() : null,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showApplyUrl = _selectedCategory == 'Hackathons' || _selectedCategory == 'Internships' || _selectedCategory == 'Opportunities';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child: const Text('PUBLISH', style: TextStyle(color: StitchTheme.primaryCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selector Pills
            const Text('Category', style: TextStyle(color: StitchTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: StitchTheme.primaryCyan,
                  backgroundColor: StitchTheme.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Post Title (Optional)',
                hintText: 'e.g. 🚀 CAMPUS HACKATHON \'24!',
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Post Content *',
                hintText: 'Share announcements, opportunities, or updates with the campus...',
              ),
            ),
            const SizedBox(height: 16),

            if (showApplyUrl) ...[
              TextField(
                controller: _applyUrlController,
                decoration: const InputDecoration(
                  labelText: 'Application / Registration URL',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link_rounded, color: StitchTheme.primaryCyan),
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _hashtagsController,
              decoration: const InputDecoration(
                labelText: 'Hashtags (Space separated)',
                hintText: 'HackUNIRISE CodeTheFuture CampusLife',
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPost,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('POST TO CAMPUS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
