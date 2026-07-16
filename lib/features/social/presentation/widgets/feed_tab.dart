import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gojocalories/core/config/env_config.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/theme/app_radius.dart';
import 'package:gojocalories/core/theme/app_spacing.dart';
import '../providers/feed_provider.dart';
import '../utils/feed_share_helper.dart';

class FeedTab extends ConsumerWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    return feedAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stackTrace) => _FeedMessage(
        icon: LucideIcons.wifiOff,
        message: 'Could not load feed',
        actionLabel: 'Retry',
        onAction: () => ref.read(feedProvider.notifier).fetchFeed(),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: const [
              _CreatePostHeader(),
              _FeedMessage(
                icon: LucideIcons.newspaper,
                message: 'No posts yet.\nBe the first to share something!',
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: posts.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const _CreatePostHeader();
            }
            final post = posts[index - 1];
            return _PostCard(
              post: post,
              index: index - 1,
              onToggleLike: () =>
                  ref.read(feedProvider.notifier).toggleLike(post.id),
            );
          },
        );
      },
    );
  }
}

class _CreatePostHeader extends StatelessWidget {
  const _CreatePostHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        24,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(
              LucideIcons.user,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                "What's on your mind?",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(LucideIcons.image, color: AppColors.primary, size: 22),
        ],
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _FeedMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 48,
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textPlaceholder),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final int index;
  final VoidCallback onToggleLike;

  const _PostCard({
    required this.post,
    required this.index,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = EnvConfig.resolveMediaUrl(post.imageUrl);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        20,
      ),
      height: 400,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: const Color(0xFFE8E8E8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _PostImageFallback(),
            )
          else
            const _PostImageFallback(),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.2, 0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    post.userName.isNotEmpty ? post.userName[0] : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(post.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(LucideIcons.ellipsis, color: Colors.white, size: 20),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (post.content != null && post.content!.isNotEmpty)
                    Text(
                      post.content!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onToggleLike,
                        child: _PostActionOverlay(
                          icon: LucideIcons.heart,
                          label: '${post.likesCount}',
                          isActive: post.isLiked,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const _PostActionOverlay(
                        icon: LucideIcons.messageCircle,
                        label: '0',
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          shareFeedPostAsImage(context, post);
                        },
                        child: const _PostActionOverlay(
                          icon: LucideIcons.send,
                          label: '',
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        LucideIcons.bookmark,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.05);
  }
}

class _PostImageFallback extends StatelessWidget {
  const _PostImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD8D8D8),
      child: const Center(
        child: Icon(
          LucideIcons.image,
          size: 48,
          color: Colors.white54,
        ),
      ),
    );
  }
}

String _formatTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inDays >= 1) return '${diff.inDays}d ago';
  if (diff.inHours >= 1) return '${diff.inHours}h ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
  return 'Just now';
}

class _PostActionOverlay extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _PostActionOverlay({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? Colors.red : Colors.white,
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
