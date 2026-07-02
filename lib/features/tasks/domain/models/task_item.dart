import '../duration_parser.dart';

class TaskItem {
  final String id;
  final String title;
  final String? description;
  final int durationSeconds;
  final bool completed;
  final DateTime day;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TaskItem({
    required this.id,
    required this.title,
    this.description,
    required this.durationSeconds,
    required this.completed,
    required this.day,
    required this.createdAt,
    this.completedAt,
  });

  int get durationMinutes => (durationSeconds / 60).ceil();

  String get durationLabel => formatTaskDuration(durationSeconds);

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    int? durationSeconds,
    bool? completed,
    DateTime? day,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool clearDescription = false,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
      day: day ?? this.day,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'duration_seconds': durationSeconds,
        'completed': completed,
        'day': day.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final seconds = json['duration_seconds'] as int? ??
        ((json['duration_minutes'] as int? ?? 30) * 60);
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      durationSeconds: seconds,
      completed: json['completed'] as bool? ?? false,
      day: DateTime.parse(json['day'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool isOnDay(DateTime date) =>
      dateOnly(day) == dateOnly(date);
}
