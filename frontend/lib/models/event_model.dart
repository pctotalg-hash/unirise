class EventModel {
  final String id;
  final String title;
  final String description;
  final String? clubName;
  final String? clubLogo;
  final DateTime date;
  final String time;
  final String location;
  final String? registrationUrl;
  final String? image;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.clubName,
    this.clubLogo,
    required this.date,
    required this.time,
    required this.location,
    this.registrationUrl,
    this.image,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    var c = json['clubId'];
    return EventModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      clubName: c is Map ? c['name'] : null,
      clubLogo: c is Map ? c['logo'] : null,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      time: json['time'] ?? '10:00 AM',
      location: json['location'] ?? 'Campus Auditorium',
      registrationUrl: json['registrationUrl'],
      image: json['image'],
    );
  }
}
