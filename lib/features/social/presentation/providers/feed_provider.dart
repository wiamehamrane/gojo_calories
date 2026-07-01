import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';

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
      final data = await ref.read(feedRepositoryProvider).getFeed();
      state = AsyncValue.data(data.map((p) => Post.fromJson(p)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleLike(String postId) async {
    final currentPosts = state.value;
    if (currentPosts == null) return;

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
      await ref.read(feedRepositoryProvider).toggleLike(postId);
    } catch (e) {
      state = AsyncValue.data(currentPosts);
    }
  }

  Future<bool> createPost({String? content, File? imageFile}) async {
    try {
      await ref.read(feedRepositoryProvider).createPost(
            content: content,
            imageFile: imageFile,
          );
      await fetchFeed();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final feedProvider = NotifierProvider<FeedNotifier, AsyncValue<List<Post>>>(
  FeedNotifier.new,
);
