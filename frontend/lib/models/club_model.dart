import 'user_model.dart';

class ClubModel {
  final String id;
  final String name;
  final String logo;
  final String coverImage;
  final String tagline;
  final String description;
  final String category;
  final bool isVerified;
  final String college;
  final UserModel? coordinator;
  final int membersCount;

  ClubModel({
    required this.id,
    required this.name,
    required this.logo,
    required this.coverImage,
    required this.tagline,
    required this.description,
    required this.category,
    required this.isVerified,
    required this.college,
    this.coordinator,
    required this.membersCount,
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'] ?? 'https://images.unsplash.com/photo-1517048676732-d65bc937f952?w=500',
      coverImage: json['coverImage'] ?? 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=1200',
      tagline: json['tagline'] ?? 'Official Campus Club',
      description: json['description'] ?? 'Innovating together on campus.',
      category: json['category'] ?? 'Technology',
      isVerified: json['isVerified'] ?? true,
      college: json['college'] ?? 'State Institute of Technology',
      coordinator: json['coordinatorId'] is Map ? UserModel.fromJson(json['coordinatorId']) : null,
      membersCount: (json['members'] as List?)?.length ?? 0,
    );
  }
}
