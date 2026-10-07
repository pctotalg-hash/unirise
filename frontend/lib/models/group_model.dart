import 'user_model.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final UserModel? admin;
  final List<UserModel> members;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    this.admin,
    required this.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? 'Campus Community Group',
      image: json['image'] ?? 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=500',
      admin: json['adminId'] is Map ? UserModel.fromJson(json['adminId']) : null,
      members: (json['members'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((m) => UserModel.fromJson(m))
              .toList() ??
          [],
    );
  }
}
