import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/progress_photos_repository.dart';
import '../../domain/models/progress_photo.dart';

final progressPhotosRepositoryProvider =
    Provider<ProgressPhotosRepository>((ref) => ProgressPhotosRepository());

class ProgressPhotosNotifier extends Notifier<AsyncValue<List<ProgressPhoto>>> {
  @override
  AsyncValue<List<ProgressPhoto>> build() {
    fetchPhotos();
    return const AsyncValue.loading();
  }

  Future<void> fetchPhotos() async {
    try {
      final data =
          await ref.read(progressPhotosRepositoryProvider).getPhotos();
      state = AsyncValue.data(
        data
            .map(
              (e) => ProgressPhoto.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> uploadPhoto(
    File imageFile, {
    String? note,
    BodyPose? pose,
    DateTime? photoDate,
  }) async {
    try {
      await ref.read(progressPhotosRepositoryProvider).uploadPhoto(
            imageFile,
            note: note,
            pose: pose?.id,
            photoDate: photoDate,
          );
      await fetchPhotos();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePhoto(String id) async {
    try {
      await ref.read(progressPhotosRepositoryProvider).deletePhoto(id);
      final current = state.value;
      if (current != null) {
        state = AsyncValue.data(current.where((p) => p.id != id).toList());
      } else {
        await fetchPhotos();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

final progressPhotosProvider =
    NotifierProvider<ProgressPhotosNotifier, AsyncValue<List<ProgressPhoto>>>(
  ProgressPhotosNotifier.new,
);

DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// Photos grouped by calendar day, newest day first. Legacy photos with no
/// pose are still grouped so nothing is lost from a user's existing timeline.
final progressDaysProvider = Provider<List<ProgressDay>>((ref) {
  final photos = ref.watch(progressPhotosProvider).value ?? const [];
  final map = <DateTime, List<ProgressPhoto>>{};
  for (final p in photos) {
    map.putIfAbsent(_dayKey(p.photoDate), () => []).add(p);
  }
  final days = map.entries
      .map((e) => ProgressDay(date: e.key, photos: e.value))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return days;
});

/// The set of poses already captured today — drives the "you still need X" UI.
final todayCompletedPosesProvider = Provider<Set<BodyPose>>((ref) {
  final today = _dayKey(DateTime.now());
  final days = ref.watch(progressDaysProvider);
  for (final d in days) {
    if (_dayKey(d.date) == today) return d.completedPoses;
  }
  return <BodyPose>{};
});
