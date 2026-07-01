import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';

class Memory {
  final String id;
  final String imageUrl;
  final String? caption;
  final bool isPrivate;
  final DateTime createdAt;

  Memory({
    required this.id,
    required this.imageUrl,
    this.caption,
    required this.isPrivate,
    required this.createdAt,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'],
      imageUrl: json['image_url'],
      caption: json['caption'],
      isPrivate: json['is_private'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class MemoriesNotifier extends Notifier<AsyncValue<List<Memory>>> {
  @override
  AsyncValue<List<Memory>> build() {
    fetchMemories();
    return const AsyncValue.loading();
  }

  Future<void> fetchMemories() async {
    state = const AsyncValue.loading();
    try {
      final data = await ref.read(memoriesRepositoryProvider).getMemories();
      state = AsyncValue.data(data.map((m) => Memory.fromJson(m)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> uploadMemory(
    File imageFile, {
    String? caption,
    bool isPrivate = true,
  }) async {
    try {
      await ref.read(memoriesRepositoryProvider).uploadMemory(
            imageFile,
            caption: caption,
            isPrivate: isPrivate,
          );
      await fetchMemories();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteMemory(String id) async {
    try {
      await ref.read(memoriesRepositoryProvider).deleteMemory(id);
      await fetchMemories();
    } catch (_) {}
  }
}

final memoriesProvider =
    NotifierProvider<MemoriesNotifier, AsyncValue<List<Memory>>>(
  MemoriesNotifier.new,
);
