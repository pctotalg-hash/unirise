import 'user_model.dart';

class MessageModel {
  final String id;
  final UserModel? sender;
  final String? receiverId;
  final String? groupId;
  final bool isPublicCampusChat;
  final String content;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    this.sender,
    this.receiverId,
    this.groupId,
    required this.isPublicCampusChat,
    required this.content,
    required this.isEdited,
    required this.isDeleted,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? '',
      sender: json['senderId'] is Map ? UserModel.fromJson(json['senderId']) : null,
      receiverId: json['receiverId']?.toString(),
      groupId: json['groupId']?.toString(),
      isPublicCampusChat: json['isPublicCampusChat'] ?? false,
      content: json['content'] ?? '',
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
