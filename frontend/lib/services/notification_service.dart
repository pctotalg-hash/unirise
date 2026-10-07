import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  static Future<Map<String, dynamic>> getNotifications() async {
    final res = await ApiClient.get('/notifications');
    final list = ((res['notifications'] ?? []) as List).map((n) => NotificationModel.fromJson(n)).toList();
    final count = res['unreadCount'] ?? 0;
    return {
      'notifications': list,
      'unreadCount': count,
    };
  }

  static Future<void> markAsRead(String id) async {
    await ApiClient.put('/notifications/$id/read', {});
  }

  static Future<void> markAllAsRead() async {
    await ApiClient.put('/notifications/read-all', {});
  }

  static Future<void> deleteNotification(String id) async {
    await ApiClient.delete('/notifications/$id');
  }
}
