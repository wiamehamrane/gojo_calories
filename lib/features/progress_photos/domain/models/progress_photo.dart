import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The four standardized angles captured by the guided flow, in capture order.
enum BodyPose { front, left, right, back }

extension BodyPoseX on BodyPose {
  /// Wire value stored on the server (must match backend VALID_POSES).
  String get id {
    switch (this) {
      case BodyPose.front:
        return 'front';
      case BodyPose.left:
        return 'left';
      case BodyPose.right:
        return 'right';
      case BodyPose.back:
        return 'back';
    }
  }

  /// Short label for chips/badges.
  String get label {
    switch (this) {
      case BodyPose.front:
        return 'Front';
      case BodyPose.left:
        return 'Left side';
      case BodyPose.right:
        return 'Right side';
      case BodyPose.back:
        return 'Back';
    }
  }

  /// One-line instruction shown during capture.
  String get instruction {
    switch (this) {
      case BodyPose.front:
        return 'Stand tall facing the camera, arms slightly away from your body.';
      case BodyPose.left:
        return 'Turn 90° so your left side faces the camera. Arms relaxed.';
      case BodyPose.right:
        return 'Turn 90° so your right side faces the camera. Arms relaxed.';
      case BodyPose.back:
        return 'Turn around with your back to the camera, standing tall.';
    }
  }

  IconData get icon {
    switch (this) {
      case BodyPose.front:
        return LucideIcons.user;
      case BodyPose.left:
        return LucideIcons.arrowLeft;
      case BodyPose.right:
        return LucideIcons.arrowRight;
      case BodyPose.back:
        return LucideIcons.userX;
    }
  }

  static BodyPose? fromId(String? value) {
    switch (value) {
      case 'front':
        return BodyPose.front;
      case 'left':
        return BodyPose.left;
      case 'right':
        return BodyPose.right;
      case 'back':
        return BodyPose.back;
      default:
        return null;
    }
  }
}

/// Canonical ordered list of the four required poses.
const List<BodyPose> kRequiredPoses = [
  BodyPose.front,
  BodyPose.left,
  BodyPose.right,
  BodyPose.back,
];

class ProgressPhoto {
  final String id;
  final String imageUrl;
  final String? note;
  final BodyPose? pose;
  final DateTime photoDate;
  final DateTime? createdAt;

  ProgressPhoto({
    required this.id,
    required this.imageUrl,
    this.note,
    this.pose,
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
      pose: BodyPoseX.fromId(json['pose'] as String?),
      photoDate: dateRaw != null
          ? DateTime.tryParse(dateRaw) ?? DateTime.now()
          : DateTime.now(),
      createdAt: createdRaw != null ? DateTime.tryParse(createdRaw) : null,
    );
  }
}

/// All photos taken on a single calendar day, grouped for the timeline.
class ProgressDay {
  final DateTime date;
  final List<ProgressPhoto> photos;

  ProgressDay({required this.date, required this.photos});

  /// Photo for a given pose, if one exists for the day.
  ProgressPhoto? photoFor(BodyPose pose) {
    for (final p in photos) {
      if (p.pose == pose) return p;
    }
    return null;
  }

  Set<BodyPose> get completedPoses =>
      photos.map((p) => p.pose).whereType<BodyPose>().toSet();

  int get completedCount => completedPoses.length;

  bool get isComplete => completedPoses.length >= kRequiredPoses.length;
}
