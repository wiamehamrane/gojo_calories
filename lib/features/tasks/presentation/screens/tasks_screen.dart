import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/tasks_provider.dart';
import '../widgets/task_grid_card.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  String _greeting(String lang, String name) {
    final hour = DateTime.now().hour;
    final String period;
    if (hour >= 5 && hour < 12) {
      period = Translations.t(lang, 'tasks_greeting_morning');
    } else if (hour >= 12 && hour < 18) {
      period = Translations.t(lang, 'tasks_greeting_afternoon');
    } else {
      period = Translations.t(lang, 'tasks_greeting_evening');
    }
    return '$period, $name.';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String lang,
    String taskId,
    String taskTitle,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: Translations.t(lang, 'tasks_delete_title'),
      message: Translations.t(lang, 'tasks_delete_message').replaceAll(
        '{task}',
        taskTitle,
      ),
      cancelLabel: Translations.t(lang, 'cancel'),
      confirmLabel: Translations.t(lang, 'tasks_delete'),
      destructive: true,
    );

    if (confirmed) {
      await ref.read(tasksProvider.notifier).deleteTask(taskId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final progress = ref.watch(todayProgressProvider);
    final timers = ref.watch(taskTimerProvider);
    final profile = ref.watch(profileProvider);

    final name = profile.maybeWhen(
      data: (data) {
        final raw = data['name']?.toString().trim();
        if (raw != null && raw.isNotEmpty) return raw.split(' ').first;
        return Translations.t(lang, 'tasks_friend');
      },
      orElse: () => Translations.t(lang, 'tasks_friend'),
    );

    final timeLabel = DateFormat.jm().format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(lang, name),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          Translations.t(lang, 'tasks_subtitle'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      LucideIcons.x,
                      size: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (progress.total > 0) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _DailyProgressBar(progress: progress, lang: lang),
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: todayTasks.isEmpty
                    ? _TasksEmptyState(lang: lang)
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: todayTasks.length,
                        itemBuilder: (context, index) {
                          final task = todayTasks[index];
                          final taskTimer = timers[task.id];
                          final isTimedOut = taskTimer?.timedOut ?? false;
                          final isActive = taskTimer?.isActive ?? false;
                          return TaskGridCard(
                            task: task,
                            isTimedOut: isTimedOut,
                            timedOutLabel:
                                Translations.t(lang, 'tasks_timed_out'),
                            isTimerActive: isActive,
                            liveRemainingSeconds: isActive
                                ? taskTimer!.effectiveRemaining
                                : null,
                            isTimerRunning:
                                isActive && (taskTimer?.isRunning ?? false),
                            onTap: () => context.push(
                              RoutePaths.taskTimer,
                              extra: task.id,
                            ),
                            onToggleComplete: () => ref
                                .read(tasksProvider.notifier)
                                .toggleComplete(task.id),
                            onDelete: () => _confirmDelete(
                              context,
                              ref,
                              lang,
                              task.id,
                              task.title,
                            ),
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push(RoutePaths.createTask),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: const Icon(LucideIcons.plus, size: 20),
                  label: Text(
                    Translations.t(lang, 'tasks_create'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasksEmptyState extends StatelessWidget {
  final String lang;

  const _TasksEmptyState({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                LucideIcons.listTodo,
                size: 34,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              Translations.t(lang, 'tasks_empty_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Translations.t(lang, 'tasks_empty_message'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyProgressBar extends StatelessWidget {
  final DailyProgress progress;
  final String lang;

  const _DailyProgressBar({required this.progress, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Translations.t(lang, 'tasks_daily_progress'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${progress.completed}/${progress.total}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.ratio,
              minHeight: 8,
              backgroundColor: AppColors.ringTrack,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
