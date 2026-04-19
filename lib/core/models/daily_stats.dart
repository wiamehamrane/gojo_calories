import 'dart:convert';

class DailyStats {
  final int calorieBudget;
  final int caloriesConsumed;
  final int proteinConsumed;
  final int carbsConsumed;
  final int fatConsumed;

  // targets
  final int proteinTarget;
  final int carbsTarget;
  final int fatTarget;

  DailyStats({
    required this.calorieBudget,
    this.caloriesConsumed = 0,
    this.proteinConsumed = 0,
    this.carbsConsumed = 0,
    this.fatConsumed = 0,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
  });

  DailyStats copyWith({
    int? caloriesConsumed,
    int? proteinConsumed,
    int? carbsConsumed,
    int? fatConsumed,
  }) {
    return DailyStats(
      calorieBudget: calorieBudget,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      proteinConsumed: proteinConsumed ?? this.proteinConsumed,
      carbsConsumed: carbsConsumed ?? this.carbsConsumed,
      fatConsumed: fatConsumed ?? this.fatConsumed,
      proteinTarget: proteinTarget,
      carbsTarget: carbsTarget,
      fatTarget: fatTarget,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calorieBudget': calorieBudget,
      'caloriesConsumed': caloriesConsumed,
      'proteinConsumed': proteinConsumed,
      'carbsConsumed': carbsConsumed,
      'fatConsumed': fatConsumed,
      'proteinTarget': proteinTarget,
      'carbsTarget': carbsTarget,
      'fatTarget': fatTarget,
    };
  }

  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      calorieBudget: map['calorieBudget']?.toInt() ?? 2200,
      caloriesConsumed: map['caloriesConsumed']?.toInt() ?? 0,
      proteinConsumed: map['proteinConsumed']?.toInt() ?? 0,
      carbsConsumed: map['carbsConsumed']?.toInt() ?? 0,
      fatConsumed: map['fatConsumed']?.toInt() ?? 0,
      proteinTarget: map['proteinTarget']?.toInt() ?? 150,
      carbsTarget: map['carbsTarget']?.toInt() ?? 200,
      fatTarget: map['fatTarget']?.toInt() ?? 65,
    );
  }

  String toJson() => json.encode(toMap());

  factory DailyStats.fromJson(String source) =>
      DailyStats.fromMap(json.decode(source));
}
