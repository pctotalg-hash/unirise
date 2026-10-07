class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // admin, student, club_coordinator
  final String profilePhoto;
  final String coverPhoto;
  final String college;
  final String department;
  final String year;
  final String bio;
  final List<String> skills;
  final List<String> achievements;
  final List<String> interests;
  final bool isVerified;
  final String? verifiedBadge;
  final String? verifiedClubId;
  final int connectionsCount;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.profilePhoto,
    required this.coverPhoto,
    required this.college,
    required this.department,
    required this.year,
    required this.bio,
    required this.skills,
    required this.achievements,
    required this.interests,
    required this.isVerified,
    this.verifiedBadge,
    this.verifiedClubId,
    this.connectionsCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> rawJson) {
    final json = rawJson.containsKey('user') && rawJson['user'] is Map<String, dynamic>
        ? rawJson['user'] as Map<String, dynamic>
        : rawJson;

    final rawRole = json['role']?.toString().toLowerCase() ?? 'student';
    final String normalizedRole = rawRole.contains('admin')
        ? 'admin'
        : (rawRole.contains('coord') ? 'club_coordinator' : 'student');

    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] ?? 'Campus User',
      email: json['email'] ?? '',
      role: normalizedRole,
      profilePhoto: json['profilePhoto'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
      coverPhoto: json['coverPhoto'] ?? 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1200',
      college: json['college'] ?? 'State Institute of Technology',
      department: json['department'] ?? 'Computer Engineering',
      year: json['year'] ?? '3rd Year',
      bio: json['bio'] ?? 'Passionate developer & tech enthusiast.',
      skills: List<String>.from(json['skills'] ?? []),
      achievements: List<String>.from(json['achievements'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      isVerified: json['isVerified'] ?? false,
      verifiedBadge: json['verifiedBadge'],
      verifiedClubId: json['verifiedClubId'] is Map ? json['verifiedClubId']['_id'] : json['verifiedClubId']?.toString(),
      connectionsCount: (json['connections'] as List?)?.length ?? 0,
    );
  }
}
