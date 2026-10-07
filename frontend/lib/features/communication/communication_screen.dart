import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/stitch_theme.dart';
import '../../models/message_model.dart';
import '../../models/group_model.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({Key? key}) : super(key: key);

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _messageController = TextEditingController();

  List<MessageModel> _publicMessages = [];
  List<GroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _loadChatData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadChatData() async {
    try {
      final messages = await ChatService.getMessages('public', type: 'public');
      final groups = await ChatService.getGroups();
      if (mounted) {
        setState(() {
          _publicMessages = messages;
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendPublicMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    try {
      await ChatService.sendMessage(content: text, isPublicCampusChat: true);
      _loadChatData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('UNIRISE Communication', style: TextStyle(fontWeight: FontWeight.black)),
        backgroundColor: StitchTheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Sub-Tab 1 (DEFAULT): Open Community Public Chat
                _buildOpenChatSection(auth),

                // Sub-Tab 2: Community Groups List
                _buildGroupsSection(),

                // Sub-Tab 3: Personal 1-on-1 Chats List
                _buildPersonalSection(auth),
              ],
            ),
          ),

          // Permanent Secondary Tab Bar positioned directly ABOVE bottom navigation bar
          Container(
            color: StitchTheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TabBar(
              controller: _tabController,
              indicatorColor: StitchTheme.primaryCyan,
              labelColor: StitchTheme.primaryCyan,
              unselectedLabelColor: StitchTheme.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              tabs: const [
                Tab(text: 'Open Community'),
                Tab(text: 'Groups'),
                Tab(text: 'Personal'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenChatSection(AuthService auth) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: StitchTheme.primaryCyan))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _publicMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _publicMessages[index];
                    final isMe = msg.sender?.id == auth.currentUser?.id;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message Actions: Reply, Edit, Delete, Copy, React')),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: isMe ? StitchTheme.primaryCyan.withOpacity(0.2) : StitchTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isMe ? StitchTheme.primaryCyan : StitchTheme.cardBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  msg.sender?.name ?? 'Campus User',
                                  style: const TextStyle(color: StitchTheme.primaryCyan, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                msg.content,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Message Composer
        Container(
          padding: const EdgeInsets.all(12),
          color: StitchTheme.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: '[ + ] Type campus message...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: StitchTheme.primaryCyan),
                onPressed: _sendPublicMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsSection() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final g = _groups[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: StitchTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StitchTheme.cardBorder),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(g.image),
            ),
            title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Text(g.description, style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: StitchTheme.textMuted, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening group: ${g.name}')),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPersonalSection(AuthService auth) {
    final sampleUsers = [
      {'name': 'Rahul Sharma', 'dept': 'Computer Science', 'msg': 'Are you joining the hackathon?'},
      {'name': 'Emily Chang', 'dept': 'Software Engineering', 'msg': 'Let\'s discuss the Flutter project.'},
      {'name': 'Priya Singh', 'dept': 'Electrical Engineering', 'msg': 'Send me the robotics details.'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sampleUsers.length,
      itemBuilder: (context, index) {
        final u = sampleUsers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: StitchTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StitchTheme.cardBorder),
          ),
          child: ListTile(
            leading: Stack(
              children: [
                const CircleAvatar(
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500'),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            title: Text(u['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Text(u['msg']!, style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 12)),
            trailing: const Icon(Icons.lock_rounded, color: Colors.greenAccent, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening private chat with ${u['name']}')),
              );
            },
          ),
        );
      },
    );
  }
}
