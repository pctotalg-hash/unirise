import '../models/user_model.dart';
import '../models/club_model.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';
import '../models/group_model.dart';
import 'api_client.dart';

class SearchResultModel {
  final String query;
  final String category;
  final List<UserModel> users;
  final List<ClubModel> clubs;
  final List<PostModel> posts;
  final List<PostModel> hackathons;
  final List<PostModel> internships;
  final List<EventModel> events;
  final List<GroupModel> groups;
  final List<PostModel> opportunities;

  SearchResultModel({
    required this.query,
    required this.category,
    required this.users,
    required this.clubs,
    required this.posts,
    required this.hackathons,
    required this.internships,
    required this.events,
    required this.groups,
    required this.opportunities,
  });
}

class AISuggestionItem {
  final String type;
  final String title;
  final String subtitle;
  final String? referenceId;

  AISuggestionItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.referenceId,
  });

  factory AISuggestionItem.fromJson(Map<String, dynamic> json) {
    return AISuggestionItem(
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      referenceId: json['referenceId']?.toString(),
    );
  }
}

class AISearchResultModel {
  final String query;
  final String intent;
  final List<AISuggestionItem> suggestions;

  AISearchResultModel({
    required this.query,
    required this.intent,
    required this.suggestions,
  });
}

class SearchService {
  static Future<SearchResultModel> globalSearch(String query, {String category = 'ALL'}) async {
    try {
      final res = await ApiClient.get('/search?q=${Uri.encodeComponent(query)}&category=${Uri.encodeComponent(category)}');
      final results = (res is Map && res['results'] is Map) ? res['results'] : {};

      final usersList = (results['users'] as List?) ?? [];
      final clubsList = (results['clubs'] as List?) ?? [];
      final postsList = (results['posts'] as List?) ?? [];
      final hackathonsList = (results['hackathons'] as List?) ?? [];
      final internshipsList = (results['internships'] as List?) ?? [];
      final eventsList = (results['events'] as List?) ?? [];
      final groupsList = (results['groups'] as List?) ?? [];
      final oppsList = (results['opportunities'] as List?) ?? [];

      return SearchResultModel(
        query: (res is Map ? res['query'] : null) ?? query,
        category: (res is Map ? res['category'] : null) ?? category,
        users: usersList.map((u) => UserModel.fromJson(u)).toList(),
        clubs: clubsList.map((c) => ClubModel.fromJson(c)).toList(),
        posts: postsList.map((p) => PostModel.fromJson(p)).toList(),
        hackathons: hackathonsList.map((p) => PostModel.fromJson(p)).toList(),
        internships: internshipsList.map((p) => PostModel.fromJson(p)).toList(),
        events: eventsList.map((e) => EventModel.fromJson(e)).toList(),
        groups: groupsList.map((g) => GroupModel.fromJson(g)).toList(),
        opportunities: oppsList.map((p) => PostModel.fromJson(p)).toList(),
      );
    } catch (e) {
      return SearchResultModel(
        query: query,
        category: category,
        users: [],
        clubs: [],
        posts: [],
        hackathons: [],
        internships: [],
        events: [],
        groups: [],
        opportunities: [],
      );
    }
  }

  static Future<AISearchResultModel> getAISuggestions(String query) async {
    try {
      final res = await ApiClient.get('/search/ai?q=${Uri.encodeComponent(query)}');
      final rawSuggestions = (res is Map && res['suggestions'] is List) ? (res['suggestions'] as List) : [];

      return AISearchResultModel(
        query: (res is Map ? res['query'] : null) ?? query,
        intent: (res is Map ? res['intent'] : null) ?? 'Smart Recommendations',
        suggestions: rawSuggestions.map((s) {
          if (s is String) {
            return AISuggestionItem(type: 'recommendation', title: s, subtitle: 'AI Recommendation');
          }
          return AISuggestionItem.fromJson(s);
        }).toList(),
      );
    } catch (e) {
      return AISearchResultModel(
        query: query,
        intent: 'Campus Recommendations',
        suggestions: [],
      );
    }
  }
}
