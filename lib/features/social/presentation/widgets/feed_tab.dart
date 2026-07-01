import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/theme/app_radius.dart';
import 'package:gojocalories/core/theme/app_spacing.dart';

class FeedTab extends ConsumerWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mockup data for design demonstration
    final List<Map<String, dynamic>> mockPosts = [
      {
        'userName': 'Alex Johnson',
        'content': 'Just finished a 10km run! Feeling great. #fitness #running',
        'imageUrl': 'https://images.unsplash.com/photo-1513594422870-0935119953d0?q=80&w=800&auto=format&fit=crop',
        'likesCount': 24,
        'isLiked': true,
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'userName': 'Sarah Wilson',
        'content': 'Healthy breakfast today! Avocado toast with poached eggs. 🥑🍳',
        'imageUrl': 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=800&auto=format&fit=crop',
        'likesCount': 42,
        'isLiked': false,
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'userName': 'Mike Ross',
        'content': 'New personal record on deadlifts today! 200kg for 5 reps. 💪',
        'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=800&auto=format&fit=crop',
        'likesCount': 15,
        'isLiked': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: mockPosts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildCreatePostHeader(context);
        }
        final post = mockPosts[index - 1];
        return _buildPostCard(context, post, index - 1);
      },
    );
  }

  Widget _buildCreatePostHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 24),
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
            child: const Icon(LucideIcons.user, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: const Text(
                "What's on your mind?",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(LucideIcons.image, color: AppColors.primary, size: 22),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post, int index) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 20),
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        image: DecorationImage(
          image: NetworkImage(post['imageUrl']),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
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

          // User Info (Top)
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
                    post['userName'][0],
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['userName'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '2h ago',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(LucideIcons.ellipsis, color: Colors.white, size: 20),
              ],
            ),
          ),

          // Content and Actions (Bottom)
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
                  Text(
                    post['content'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _PostActionOverlay(
                        icon: LucideIcons.heart,
                        label: '${post['likesCount']}',
                        isActive: post['isLiked'],
                      ),
                      const SizedBox(width: 16),
                      const _PostActionOverlay(
                        icon: LucideIcons.messageCircle,
                        label: '12',
                      ),
                      const SizedBox(width: 16),
                      const _PostActionOverlay(
                        icon: LucideIcons.send,
                        label: '',
                      ),
                      const Spacer(),
                      const Icon(LucideIcons.bookmark, color: Colors.white, size: 22),
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
