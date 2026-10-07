import 'user_model.dart';

class PositionModel {
  final String id;
  final String clubId;
  final UserModel? user;
  final String positionName;
  final String status;
  final DateTime assignedAt;
  final UserModel? previousHolder;

  PositionModel({
    required this.id,
    required this.clubId,
    this.user,
    required this.positionName,
    required this.status,
    required this.assignedAt,
    this.previousHolder,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: json['_id'] ?? '',
      clubId: json['clubId'] is Map ? json['clubId']['_id'] : (json['clubId']?.toString() ?? ''),
      user: json['userId'] is Map ? UserModel.fromJson(json['userId']) : null,
      positionName: json['positionName'] ?? 'Member',
      status: json['status'] ?? 'ACTIVE',
      assignedAt: json['assignedAt'] != null ? DateTime.parse(json['assignedAt']) : DateTime.now(),
      previousHolder: json['previousHolder'] is Map ? UserModel.fromJson(json['previousHolder']) : null,
    );
  }
}
