import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../providers/feed_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FeedTab extends ConsumerWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).fetchFeed(),
      color: AppColors.primary,
      child: feedAsync.when(
        data: (posts) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildCreatePostHeader(context, ref);
            }
            final post = posts[index - 1];
            return _buildPostCard(context, ref, post, index - 1);
          },
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load feed'),
              TextButton(
                onPressed: () => ref.read(feedProvider.notifier).fetchFeed(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePostHeader(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(LucideIcons.user, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _showCreatePostBottomSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  "What's on your mind?",
                  style: TextStyle(color: AppColors.inactive, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(LucideIcons.image, color: AppColors.primary, size: 22),
            onPressed: () => _pickAndCreatePost(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, WidgetRef ref, Post post, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '👤',
                    style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().add_jm().format(post.createdAt.toLocal()),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.ellipsis, size: 20),
                  color: AppColors.inactive,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Post Image (if any)
          if (post.imageUrl != null)
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                image: DecorationImage(
                  image: NetworkImage(post.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Post Content
          if (post.content != null && post.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                post.content!,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          // Actions
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => ref.read(feedProvider.notifier).toggleLike(post.id),
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked ? LucideIcons.heart : LucideIcons.heart,
                            size: 22,
                            color: post.isLiked ? Colors.red : AppColors.textPrimary,
                            fill: post.isLiked ? 1.0 : 0.0,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.likesCount}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: post.isLiked ? Colors.red : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    const Icon(LucideIcons.messageCircle, size: 22, color: AppColors.textPrimary),
                    const SizedBox(width: 24),
                    const Icon(LucideIcons.send, size: 22, color: AppColors.textPrimary),
                    const Spacer(),
                    const Icon(LucideIcons.bookmark, size: 22, color: AppColors.textPrimary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
  }

  void _showCreatePostBottomSheet(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Post',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surfaceMuted,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (textController.text.isNotEmpty) {
                    await ref.read(feedProvider.notifier).createPost(content: textController.text);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndCreatePost(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      // Show a simple dialog for caption
      if (!context.mounted) return;
      final caption = await _showCaptionDialog(context);
      await ref.read(feedProvider.notifier).createPost(
        content: caption,
        imageFile: File(pickedFile.path),
      );
    }
  }

  Future<String?> _showCaptionDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a caption'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Optional...'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Post')),
        ],
      ),
    );
  }
}
