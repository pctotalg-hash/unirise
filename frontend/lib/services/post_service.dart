import '../models/post_model.dart';
import 'api_client.dart';

class PostService {
  static Future<List<PostModel>> getPosts({String? category, String? search}) async {
    String queryStr = '';
    List<String> params = [];
    if (category != null && category.isNotEmpty) params.add('category=${Uri.encodeComponent(category)}');
    if (search != null && search.isNotEmpty) params.add('search=${Uri.encodeComponent(search)}');
    if (params.isNotEmpty) queryStr = '?${params.join('&')}';

    final res = await ApiClient.get('/posts$queryStr');
    return (res as List).map((p) => PostModel.fromJson(p)).toList();
  }

  static Future<PostModel> getPostById(String id) async {
    final res = await ApiClient.get('/posts/$id');
    return PostModel.fromJson(res);
  }

  static Future<PostModel> createPost({
    required String content,
    String? title,
    required String category,
    List<String>? hashtags,
    List<String>? media,
    String? applyUrl,
    String? externalUrl,
    DateTime? eventDate,
    String? location,
    String? clubId,
  }) async {
    final body = {
      'content': content,
      'title': title,
      'category': category,
      'hashtags': hashtags ?? [],
      'media': media ?? [],
      'applyUrl': applyUrl,
      'externalUrl': externalUrl,
      'eventDate': eventDate?.toIso8601String(),
      'location': location,
      'clubId': clubId,
    };
    final res = await ApiClient.post('/posts', body);
    return PostModel.fromJson(res);
  }

  static Future<Map<String, dynamic>> likePost(String id) async {
    final res = await ApiClient.post('/posts/$id/like', {});
    return res as Map<String, dynamic>;
  }

  static Future<List<CommentModel>> commentPost(String id, String text) async {
    final res = await ApiClient.post('/posts/$id/comment', {'text': text});
    return (res as List).map((c) => CommentModel.fromJson(c)).toList();
  }

  static Future<void> sharePost(String id) async {
    await ApiClient.post('/posts/$id/share', {});
  }
}
