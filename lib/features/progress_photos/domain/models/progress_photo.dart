class ProgressPhoto {
  final String id;
  final String imageUrl;
  final String? note;
  final DateTime photoDate;
  final DateTime? createdAt;

  ProgressPhoto({
    required this.id,
    required this.imageUrl,
    this.note,
    required this.photoDate,
    this.createdAt,
  });

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['photo_date'] as String?;
    final createdRaw = json['created_at'] as String?;
    return ProgressPhoto(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      note: json['note'] as String?,
      photoDate: dateRaw != null
          ? DateTime.tryParse(dateRaw) ?? DateTime.now()
          : DateTime.now(),
      createdAt: createdRaw != null ? DateTime.tryParse(createdRaw) : null,
    );
  }
}
