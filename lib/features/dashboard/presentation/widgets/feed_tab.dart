import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/theme/app_radius.dart';
import 'package:gojocalories/core/theme/app_spacing.dart';
import 'package:gojocalories/core/theme/app_text_styles.dart';

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
        'imageUrl': null,
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
          Icon(LucideIcons.image, color: AppColors.primary, size: 22),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post, int index) {
    final bool hasImage = post['imageUrl'] != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    post['userName'][0],
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['userName'],
                      style: AppTextStyles.bodyBold,
                    ),
                    Text(
                      '2 hours ago', // Simplified for mockup
                      style: AppTextStyles.bodyRegular.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(LucideIcons.ellipsis, color: AppColors.inactive, size: 20),
              ],
            ),
          ),

          // Post Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              post['content'],
              style: AppTextStyles.bodyRegular.copyWith(color: AppColors.textPrimary, height: 1.5),
            ),
          ),

          // Post Image
          if (hasImage)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(post['imageUrl']),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _PostAction(
                  icon: post['isLiked'] ? LucideIcons.heart : LucideIcons.heart,
                  label: '${post['likesCount']}',
                  color: post['isLiked'] ? Colors.red : AppColors.textPrimary,
                  isActive: post['isLiked'],
                ),
                const SizedBox(width: 20),
                const _PostAction(
                  icon: LucideIcons.messageCircle,
                  label: '12',
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 20),
                const _PostAction(
                  icon: LucideIcons.send,
                  label: '',
                  color: AppColors.textPrimary,
                ),
                const Spacer(),
                const Icon(LucideIcons.bookmark, color: AppColors.inactive, size: 22),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.05);
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;

  const _PostAction({
    required this.icon,
    required this.label,
    required this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: color,
          fill: isActive ? 1.0 : 0.0,
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
