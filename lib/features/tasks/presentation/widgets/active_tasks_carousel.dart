import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/duration_parser.dart';
import '../providers/tasks_provider.dart';

class ActiveTasksCarousel extends ConsumerStatefulWidget {
  const ActiveTasksCarousel({super.key});

  @override
  ConsumerState<ActiveTasksCarousel> createState() =>
      _ActiveTasksCarouselState();
}

class _ActiveTasksCarouselState extends ConsumerState<ActiveTasksCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final entries = ref.watch(activeTaskEntriesProvider);

    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: SizedBox(
        height: 160,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              SizedBox(
                height: 140,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: entries.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: _ActiveTaskCard(
                        entry: entry,
                        lang: lang,
                        onTap: () => context.push(
                          RoutePaths.taskTimer,
                          extra: entry.task.id,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (entries.length > 1)
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(entries.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 4,
                        width: _currentPage == index ? 12 : 4,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryMid
                              : AppColors.inactive.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveTaskCard extends StatelessWidget {
  final ActiveTaskEntry entry;
  final String lang;
  final VoidCallback onTap;

  const _ActiveTaskCard({
    required this.entry,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = entry.timer.effectiveRemaining;
    final progress = entry.timer.progress.clamp(0.0, 1.0);
    final isRunning = entry.timer.isRunning;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        backgroundColor: AppColors.ringTrack,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(
                      isRunning ? LucideIcons.play : LucideIcons.pause,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatTaskDuration(remaining),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isRunning
                          ? Translations.t(lang, 'tasks_in_progress')
                          : Translations.t(lang, 'tasks_paused'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.inactive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
