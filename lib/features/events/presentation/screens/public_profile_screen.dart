import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../providers/shared_meals_provider.dart';

final _publicProfileProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, userId) async {
    return ref.read(sharedMealsRepositoryProvider).getPublicProfile(userId);
  },
);

class PublicProfileScreen extends ConsumerWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_publicProfileProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            size: 24,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 14)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              AppErrorHandler.message(e),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (profile) {
          final isPublic = profile['is_public'] as bool? ?? false;
          final name = profile['name'] as String? ?? 'Gojo member';
          if (!isPublic) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.surfaceMuted,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This profile is private.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final age = profile['age'];
          final gender = profile['gender'] as String?;
          final mealsShared = (profile['meals_shared'] as num?)?.toInt() ?? 0;
          final phone = profile['phone'] as String?;

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (age != null || (gender != null && gender.isNotEmpty)) ...[
                const SizedBox(height: 6),
                Text(
                  [
                    if (age != null) '$age yrs',
                    if (gender != null && gender.isNotEmpty) gender,
                  ].join(' · '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.utensils,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Meals shared',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$mealsShared',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.phone, size: 18, color: AppColors.primaryDark),
                      const SizedBox(width: 12),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
