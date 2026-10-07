import 'user_model.dart';
import 'club_model.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhoto;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    var u = json['userId'];
    return CommentModel(
      id: json['_id'] ?? '',
      userId: u is Map ? u['_id'] : (u?.toString() ?? ''),
      userName: u is Map ? u['name'] : 'Campus User',
      userPhoto: u is Map ? (u['profilePhoto'] ?? '') : '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class PostModel {
  final String id;
  final UserModel? author;
  final ClubModel? club;
  final String title;
  final String content;
  final String category;
  final List<String> hashtags;
  final List<String> media;
  final String? externalUrl;
  final String? applyUrl;
  final DateTime? eventDate;
  final String? location;
  final List<String> likes;
  final List<CommentModel> comments;
  final int sharesCount;
  final DateTime createdAt;

  PostModel({
    required this.id,
    this.author,
    this.club,
    required this.title,
    required this.content,
    required this.category,
    required this.hashtags,
    required this.media,
    this.externalUrl,
    this.applyUrl,
    this.eventDate,
    this.location,
    required this.likes,
    required this.comments,
    required this.sharesCount,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['_id'] ?? '',
      author: json['authorId'] is Map ? UserModel.fromJson(json['authorId']) : null,
      club: json['clubId'] is Map ? ClubModel.fromJson(json['clubId']) : null,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'Student Posts',
      hashtags: List<String>.from(json['hashtags'] ?? []),
      media: List<String>.from(json['media'] ?? []),
      externalUrl: json['externalUrl'],
      applyUrl: json['applyUrl'],
      eventDate: json['eventDate'] != null ? DateTime.tryParse(json['eventDate']) : null,
      location: json['location'],
      likes: (json['likes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      comments: (json['comments'] as List?)?.map((c) => CommentModel.fromJson(c)).toList() ?? [],
      sharesCount: json['sharesCount'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
