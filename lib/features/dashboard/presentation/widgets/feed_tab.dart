import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

class FeedTab extends ConsumerWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildPostCard(index);
      },
    );
  }

  Widget _buildPostCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  backgroundColor: AppColors.primaryLight,
                  child: const Text('👤', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitness Enthusiast',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '2 hours ago',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(LucideIcons.ellipsis, color: AppColors.inactive, size: 20),
              ],
            ),
          ),
          // Post Image
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              image: DecorationImage(
                image: NetworkImage('https://picsum.photos/seed/${index + 42}/600/600'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.heart, size: 22, color: AppColors.textPrimary),
                    const SizedBox(width: 16),
                    const Icon(LucideIcons.messageCircle, size: 22, color: AppColors.textPrimary),
                    const SizedBox(width: 16),
                    const Icon(LucideIcons.send, size: 22, color: AppColors.textPrimary),
                    const Spacer(),
                    const Icon(LucideIcons.bookmark, size: 22, color: AppColors.textPrimary),
                  ],
                ),
                const SizedBox(height: 10),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'fitness_lover ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'Just finished an amazing workout! Feeling stronger every day. #fitness #health',
                      ),
                    ],
                  ),
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
  }
}
