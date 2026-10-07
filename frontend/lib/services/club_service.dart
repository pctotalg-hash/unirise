import '../models/club_model.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';
import '../models/position_model.dart';
import 'api_client.dart';

class ClubService {
  static Future<List<ClubModel>> getClubs() async {
    final res = await ApiClient.get('/clubs');
    return (res as List).map((c) => ClubModel.fromJson(c)).toList();
  }

  static Future<ClubModel> getClubById(String id) async {
    final res = await ApiClient.get('/clubs/$id');
    return ClubModel.fromJson(res);
  }

  static Future<List<PostModel>> getClubPosts(String clubId) async {
    final res = await ApiClient.get('/clubs/$clubId/posts');
    return (res as List).map((p) => PostModel.fromJson(p)).toList();
  }

  static Future<List<EventModel>> getClubEvents(String clubId) async {
    final res = await ApiClient.get('/clubs/$clubId/events');
    return (res as List).map((e) => EventModel.fromJson(e)).toList();
  }

  static Future<List<PositionModel>> getClubCoreTeam(String clubId) async {
    final res = await ApiClient.get('/clubs/$clubId/core-team');
    return (res as List).map((p) => PositionModel.fromJson(p)).toList();
  }

  static Future<void> updateClub(String id, Map<String, dynamic> data) async {
    await ApiClient.put('/clubs/$id', data);
  }

  static Future<void> transferPosition(String clubId, String positionId, String newUserId) async {
    await ApiClient.post('/clubs/$clubId/positions/$positionId/transfer', {
      'newUserId': newUserId,
    });
  }

  static Future<void> assignPosition(String clubId, String userId, String positionName) async {
    await ApiClient.post('/clubs/$clubId/positions', {
      'userId': userId,
      'positionName': positionName,
    });
  }
}
