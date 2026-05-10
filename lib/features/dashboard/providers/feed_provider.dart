import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String? content;
  final String? imageUrl;
  final int likesCount;
  final bool isLiked;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    this.content,
    this.imageUrl,
    required this.likesCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user']['name'] ?? 'User',
      content: json['content'],
      imageUrl: json['image_url'],
      likesCount: json['likes_count'],
      isLiked: json['is_liked'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Post copyWith({int? likesCount, bool? isLiked}) {
    return Post(
      id: id,
      userId: userId,
      userName: userName,
      content: content,
      imageUrl: imageUrl,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }
}

class FeedNotifier extends Notifier<AsyncValue<List<Post>>> {
  @override
  AsyncValue<List<Post>> build() {
    fetchFeed();
    return const AsyncValue.loading();
  }

  Future<void> fetchFeed() async {
    try {
      final res = await ApiClient.instance.get('feed');
      if (res.statusCode == 200) {
        final List<dynamic> data = res.data;
        state = AsyncValue.data(data.map((p) => Post.fromJson(p)).toList());
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleLike(String postId) async {
    final currentPosts = state.value;
    if (currentPosts == null) return;

    // Optimistic UI update
    final updatedPosts = currentPosts.map((p) {
      if (p.id == postId) {
        final newIsLiked = !p.isLiked;
        return p.copyWith(
          isLiked: newIsLiked,
          likesCount: p.likesCount + (newIsLiked ? 1 : -1),
        );
      }
      return p;
    }).toList();
    state = AsyncValue.data(updatedPosts);

    try {
      await ApiClient.instance.post('feed/posts/$postId/like');
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentPosts);
    }
  }

  Future<bool> createPost({String? content, File? imageFile}) async {
    try {
      FormData formData = FormData.fromMap({
        if (content != null) "content": content,
        if (imageFile != null)
          "file": await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
      });

      final res = await ApiClient.instance.post(
        'feed/posts',
        data: formData,
      );

      if (res.statusCode == 201) {
        fetchFeed();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final feedProvider = NotifierProvider<FeedNotifier, AsyncValue<List<Post>>>(() {
  return FeedNotifier();
});
