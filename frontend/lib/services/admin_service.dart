import '../models/user_model.dart';
import '../models/club_model.dart';
import 'api_client.dart';

class AdminService {
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await ApiClient.get('/admin/dashboard');
    return res as Map<String, dynamic>;
  }

  static Future<List<UserModel>> getAdminUsers() async {
    final res = await ApiClient.get('/admin/users');
    return (res as List).map((u) => UserModel.fromJson(u)).toList();
  }

  static Future<List<ClubModel>> getAdminClubs() async {
    final res = await ApiClient.get('/admin/clubs');
    return (res as List).map((c) => ClubModel.fromJson(c)).toList();
  }

  static Future<void> verifyUser(String userId, bool isVerified, String? verifiedBadge) async {
    await ApiClient.post('/admin/verify-user', {
      'userId': userId,
      'isVerified': isVerified,
      'verifiedBadge': verifiedBadge,
    });
  }

  static Future<void> verifyClub(String clubId, bool isVerified) async {
    await ApiClient.post('/admin/verify-club', {
      'clubId': clubId,
      'isVerified': isVerified,
    });
  }

  static Future<void> deletePostAdmin(String postId) async {
    await ApiClient.delete('/admin/posts/$postId');
  }
}
