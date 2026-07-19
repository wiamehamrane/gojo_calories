import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/progress_photos_repository.dart';
import '../../domain/models/progress_photo.dart';

final progressPhotosRepositoryProvider =
    Provider<ProgressPhotosRepository>((ref) => ProgressPhotosRepository());

class ProgressPhotosNotifier extends Notifier<AsyncValue<List<ProgressPhoto>>> {
  @override
  AsyncValue<List<ProgressPhoto>> build() {
    Future.microtask(fetchPhotos);
    return const AsyncValue.loading();
  }

  Future<void> fetchPhotos() async {
    try {
      final data =
          await ref.read(progressPhotosRepositoryProvider).getPhotos();
      state = AsyncValue.data(
        _withInferredPoses(
          data
              .map(
                (e) => ProgressPhoto.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
        ),
      );
    } catch (e, st) {
      debugPrint('progressPhotos fetch failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Uploads one photo and merges the server response into state immediately.
  Future<ProgressPhoto?> uploadPhoto(
    File imageFile, {
    String? note,
    BodyPose? pose,
    DateTime? photoDate,
  }) async {
    try {
      final json = await ref.read(progressPhotosRepositoryProvider).uploadPhoto(
            imageFile,
            note: note,
            pose: pose?.id,
            photoDate: photoDate,
          );
      var uploaded = ProgressPhoto.fromJson(json);
      // If the API omitted pose (older deploy / form parse miss), keep the one we sent.
      if (pose != null && uploaded.pose == null) {
        uploaded = uploaded.copyWith(pose: pose);
      }

      final current = List<ProgressPhoto>.from(state.value ?? const []);
      // Replace same day+pose if present, otherwise prepend.
      current.removeWhere(
        (p) =>
            uploaded.pose != null &&
            p.pose == uploaded.pose &&
            _sameDay(p.photoDate, uploaded.photoDate),
      );
      current.insert(0, uploaded);
      state = AsyncValue.data(_withInferredPoses(current));
      return uploaded;
    } catch (e, st) {
      debugPrint('progressPhotos upload failed: $e\n$st');
      return null;
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
    } catch (e) {
      debugPrint('progressPhotos delete failed: $e');
      return false;
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// For days where photos were saved without a pose, assign remaining angles in
/// capture order so the Today card / timeline stay accurate.
List<ProgressPhoto> _withInferredPoses(List<ProgressPhoto> photos) {
  final byDay = <DateTime, List<ProgressPhoto>>{};
  for (final p in photos) {
    final key = DateTime(p.photoDate.year, p.photoDate.month, p.photoDate.day);
    byDay.putIfAbsent(key, () => []).add(p);
  }

  final out = <ProgressPhoto>[];
  for (final dayPhotos in byDay.values) {
    final taken = <BodyPose>{
      for (final p in dayPhotos)
        if (p.pose != null) p.pose!,
    };
    final missing = dayPhotos.where((p) => p.pose == null).toList()
      ..sort((a, b) {
        final ac = a.createdAt ?? a.photoDate;
        final bc = b.createdAt ?? b.photoDate;
        return ac.compareTo(bc);
      });
    final available =
        kRequiredPoses.where((pose) => !taken.contains(pose)).toList();
    var i = 0;
    final remapped = <String, BodyPose>{};
    for (final p in missing) {
      if (i >= available.length) break;
      remapped[p.id] = available[i++];
    }
    for (final p in dayPhotos) {
      final inferred = remapped[p.id];
      out.add(inferred != null ? p.copyWith(pose: inferred) : p);
    }
  }
  return out;
}

final progressPhotosProvider =
    NotifierProvider<ProgressPhotosNotifier, AsyncValue<List<ProgressPhoto>>>(
  ProgressPhotosNotifier.new,
);

DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// Photos grouped by calendar day, newest day first.
final progressDaysProvider = Provider<List<ProgressDay>>((ref) {
  final photos = ref.watch(progressPhotosProvider).value ?? const [];
  final map = <DateTime, List<ProgressPhoto>>{};
  for (final p in photos) {
    map.putIfAbsent(_dayKey(p.photoDate), () => []).add(p);
  }
  final days = map.entries
      .map((e) => ProgressDay(date: e.key, photos: e.value))
      .where((d) => d.photos.isNotEmpty)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return days;
});

/// Poses already captured today — drives the Today card.
final todayCompletedPosesProvider = Provider<Set<BodyPose>>((ref) {
  final today = _dayKey(DateTime.now());
  final days = ref.watch(progressDaysProvider);
  for (final d in days) {
    if (_dayKey(d.date) == today) return d.completedPoses;
  }
  return <BodyPose>{};
});
