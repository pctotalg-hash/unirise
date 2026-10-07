import '../models/message_model.dart';
import '../models/group_model.dart';
import 'api_client.dart';

class ChatService {
  static Future<List<MessageModel>> getMessages(String targetId, {required String type}) async {
    final res = await ApiClient.get('/messages/$targetId?type=$type');
    return (res as List).map((m) => MessageModel.fromJson(m)).toList();
  }

  static Future<MessageModel> sendMessage({
    required String content,
    String? receiverId,
    String? groupId,
    bool isPublicCampusChat = false,
  }) async {
    final res = await ApiClient.post('/messages', {
      'content': content,
      'receiverId': receiverId,
      'groupId': groupId,
      'isPublicCampusChat': isPublicCampusChat,
    });
    return MessageModel.fromJson(res);
  }

  static Future<List<GroupModel>> getGroups() async {
    final res = await ApiClient.get('/groups');
    return (res as List).map((g) => GroupModel.fromJson(g)).toList();
  }
}
