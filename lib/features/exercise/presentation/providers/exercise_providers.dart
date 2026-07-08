import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';

String _dateKey(DateTime date) =>
    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

final dailyExercisesProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, DateTime>(
  (ref, date) async {
    return ref.read(exerciseRepositoryProvider).getExercises(
          date: _dateKey(date),
          tzOffset: date.timeZoneOffset.inMinutes,
        );
  },
);

/// All recent exercises (no date filter) — kept for backwards compatibility.
final exercisesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(exerciseRepositoryProvider).getExercises();
});
