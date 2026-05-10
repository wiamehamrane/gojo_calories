import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

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
      final res = await ApiClient.instance.get('memories');
      if (res.statusCode == 200) {
        final List<dynamic> data = res.data;
        state = AsyncValue.data(data.map((m) => Memory.fromJson(m)).toList());
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> uploadMemory(File imageFile, {String? caption, bool isPrivate = true}) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(imageFile.path, filename: fileName),
        "caption": caption,
        "is_private": isPrivate,
      }..removeWhere((k, v) => v == null));

      final res = await ApiClient.instance.post(
        'memories',
        data: formData,
      );

      if (res.statusCode == 201) {
        fetchMemories();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteMemory(String id) async {
    try {
      final res = await ApiClient.instance.delete('memories/$id');
      if (res.statusCode == 200) {
        fetchMemories();
      }
    } catch (e) {
      // Handle error
    }
  }
}

final memoriesProvider = NotifierProvider<MemoriesNotifier, AsyncValue<List<Memory>>>(() {
  return MemoriesNotifier();
});
