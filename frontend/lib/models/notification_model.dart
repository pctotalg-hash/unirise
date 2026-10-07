import 'user_model.dart';

class NotificationModel {
  final String id;
  final UserModel? sender;
  final String type;
  final String title;
  final String message;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.sender,
    required this.type,
    required this.title,
    required this.message,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      sender: json['senderId'] is Map ? UserModel.fromJson(json['senderId']) : null,
      type: json['type'] ?? 'GENERAL',
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      referenceId: json['referenceId']?.toString(),
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
