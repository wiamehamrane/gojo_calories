class Event {
  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final String eventType;
  /// Who can attend: `female`, `male`, or `mixed`.
  final String audience;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final DateTime startTime;
  final String? whatsappLink;
  final String? imageUrl;
  final List<String> imageUrls;
  final int? maxParticipants;
  final DateTime createdAt;
  final int participantsCount;
  final bool isJoined;

  Event({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    required this.eventType,
    this.audience = 'mixed',
    this.locationName,
    this.latitude,
    this.longitude,
    required this.startTime,
    this.whatsappLink,
    this.imageUrl,
    this.imageUrls = const [],
    this.maxParticipants,
    required this.createdAt,
    required this.participantsCount,
    required this.isJoined,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventType: json['event_type'] as String,
      audience: (json['audience'] as String?)?.toLowerCase() ?? 'mixed',
      locationName: json['location_name'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      startTime: DateTime.parse(json['start_time'] as String),
      whatsappLink: json['whatsapp_link'] as String?,
      imageUrl: json['image_url'] as String?,
      imageUrls: _parseImageUrls(json),
      maxParticipants: json['max_participants'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      participantsCount: json['participants_count'] as int,
      isJoined: json['is_joined'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'event_type': eventType,
      'audience': audience,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'start_time': startTime.toIso8601String(),
      'whatsapp_link': whatsappLink,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'max_participants': maxParticipants,
      'created_at': createdAt.toIso8601String(),
      'participants_count': participantsCount,
      'is_joined': isJoined,
    };
  }
}

List<String> _parseImageUrls(Map<String, dynamic> json) {
  final raw = json['image_urls'];
  if (raw is List) {
    return raw
        .whereType<String>()
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
  }
  final single = json['image_url'] as String?;
  if (single != null && single.trim().isNotEmpty) {
    return [single.trim()];
  }
  return [];
}
