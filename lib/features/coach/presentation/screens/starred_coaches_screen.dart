import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/models/coach.dart';
import '../widgets/coach_ui.dart';

final starredCoachesProvider =
    AsyncNotifierProvider<StarredCoachesNotifier, List<Coach>>(
  StarredCoachesNotifier.new,
);

class StarredCoachesNotifier extends AsyncNotifier<List<Coach>> {
  @override
  Future<List<Coach>> build() => _fetch();

  Future<List<Coach>> _fetch() {
    return ref.read(coachesRepositoryProvider).listStarred();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

class StarredCoachesScreen extends ConsumerWidget {
  const StarredCoachesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final starredAsync = ref.watch(starredCoachesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.chevronLeft,
            size: 24,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: Text(
          t('starred_coaches'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(starredCoachesProvider.notifier).refresh(),
        child: starredAsync.when(
          loading: () =>
              const Center(child: CupertinoActivityIndicator(radius: 14)),
          error: (e, _) => _MessageState(
            icon: LucideIcons.wifiOff,
            title: t('starred_coaches_load_error'),
            message: AppErrorHandler.message(e),
            actionLabel: t('retry'),
            onAction: () =>
                ref.read(starredCoachesProvider.notifier).refresh(),
          ),
          data: (coaches) {
            if (coaches.isEmpty) {
              return _MessageState(
                icon: LucideIcons.star,
                title: t('starred_coaches_empty_title'),
                message: t('starred_coaches_empty_message'),
              );
            }
            return ListView.separated(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                8,
                AppSpacing.screenPadding,
                40,
              ),
              itemCount: coaches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _StarredCoachTile(
                coach: coaches[index],
                t: t,
                onOpen: () async {
                  HapticFeedback.selectionClick();
                  await context.push(RoutePaths.coachDetailPath(coaches[index].id));
                  if (context.mounted) {
                    ref.read(starredCoachesProvider.notifier).refresh();
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StarredCoachTile extends StatelessWidget {
  final Coach coach;
  final String Function(String) t;
  final VoidCallback onOpen;

  const _StarredCoachTile({
    required this.coach,
    required this.t,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final name = coach.name?.trim().isNotEmpty == true
        ? coach.name!
        : t('coaches_unnamed');
    final initial = name.characters.first.toUpperCase();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryLight,
                backgroundImage:
                    coach.avatarUrl != null && coach.avatarUrl!.isNotEmpty
                        ? NetworkImage(coach.avatarUrl!)
                        : null,
                child: coach.avatarUrl == null || coach.avatarUrl!.isEmpty
                    ? Text(
                        initial,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xFFF5B301),
                        ),
                      ],
                    ),
                    if (coach.city?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        coach.city!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (coach.specialties.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: coach.specialties.take(3).map((s) {
                          final key = 'coach_specialty_$s';
                          final label = t(key);
                          final tint = coachSpecialtyTint(s);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tint.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              label == key ? s : label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tint,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.inactive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        Icon(icon, size: 36, color: AppColors.inactive),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 18),
          Center(
            child: FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
