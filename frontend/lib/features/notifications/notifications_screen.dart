import 'package:flutter/material.dart';
import '../../core/theme/stitch_theme.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await NotificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data['notifications'];
          _unreadCount = data['unreadCount'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAllRead() async {
    await NotificationService.markAllAsRead();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications ($_unreadCount)'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark All Read', style: TextStyle(color: StitchTheme.primaryCyan)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: StitchTheme.primaryCyan))
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications yet', style: TextStyle(color: StitchTheme.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: n.isRead ? StitchTheme.surface : StitchTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: n.isRead ? StitchTheme.cardBorder : StitchTheme.primaryCyan,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: StitchTheme.primaryCyan.withOpacity(0.2),
                          child: const Icon(Icons.notifications_rounded, color: StitchTheme.primaryCyan),
                        ),
                        title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(n.message, style: const TextStyle(color: StitchTheme.textSecondary, fontSize: 13)),
                        trailing: n.isRead
                            ? null
                            : Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.redAccent,
                                ),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
