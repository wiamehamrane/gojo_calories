import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/coach_ui.dart';

class CoachHubScreen extends ConsumerWidget {
  const CoachHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    String t(String key) => Translations.t(locale, key);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          t('coach_hub_title'),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            t('coach_hub_subtitle'),
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(duration: 280.ms),
          const SizedBox(height: 20),
          _HubCard(
            icon: LucideIcons.user,
            title: t('coach_hub_profile'),
            subtitle: t('coach_hub_profile_body'),
            onTap: () => context.push(RoutePaths.becomeCoach),
          )
              .animate()
              .fadeIn(delay: 60.ms, duration: 320.ms)
              .slideY(begin: 0.06, curve: Curves.easeOutCubic),
          const SizedBox(height: 12),
          _HubCard(
            icon: LucideIcons.layoutGrid,
            title: t('coach_hub_social'),
            subtitle: t('coach_hub_social_body'),
            onTap: () async {
              final me = await ref.read(coachesRepositoryProvider).getMe();
              final id = me.profile?.id;
              if (!context.mounted) return;
              if (id == null || id.isEmpty) {
                context.push(RoutePaths.becomeCoach);
                return;
              }
              context.push(RoutePaths.coachDetailPath(id));
            },
          )
              .animate()
              .fadeIn(delay: 90.ms, duration: 320.ms)
              .slideY(begin: 0.06, curve: Curves.easeOutCubic),
          const SizedBox(height: 12),
          _HubCard(
            icon: LucideIcons.plus,
            title: t('coach_create_post'),
            subtitle: t('coach_hub_create_post_body'),
            onTap: () => context.push(RoutePaths.coachCreatePost),
          )
              .animate()
              .fadeIn(delay: 110.ms, duration: 320.ms)
              .slideY(begin: 0.06, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CoachPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: CoachSectionCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
