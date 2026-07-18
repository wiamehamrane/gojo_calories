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
    DateTime? photoDate,
  }) async {
    try {
      await ref.read(progressPhotosRepositoryProvider).uploadPhoto(
            imageFile,
            note: note,
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
