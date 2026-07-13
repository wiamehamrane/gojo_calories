import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/task_item.dart';
import '../../domain/duration_parser.dart';
import '../providers/tasks_provider.dart';

class TaskTimerScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskTimerScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskTimerScreen> createState() => _TaskTimerScreenState();
}

class _TaskTimerScreenState extends ConsumerState<TaskTimerScreen> {
  bool _initialized = false;

  TaskItem? _findTask(List<TaskItem> tasks) {
    for (final task in tasks) {
      if (task.id == widget.taskId) return task;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final tasks = ref.watch(tasksProvider);
    final timers = ref.watch(taskTimerProvider);
    final task = _findTask(tasks);

    if (task == null) {
      return Scaffold(
        body: Center(
          child: Text(Translations.t(lang, 'tasks_not_found')),
        ),
      );
    }

    final timer = timers[task.id];

    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _initialized) return;
        _initialized = true;
        final notifier = ref.read(taskTimerProvider.notifier);
        final current = ref.read(taskTimerProvider)[task.id];
        if (current?.timedOut == true) {
          return;
        }
        if (current == null) {
          notifier.start(task);
        } else if (current.effectiveRemaining > 0) {
          notifier.resumeExisting(task.id);
        }
      });
    }

    final isTimedOut = timer?.timedOut ?? false;
    final activeTimer = timer != null && !isTimedOut ? timer : null;
    final remaining = isTimedOut
        ? 0
        : activeTimer != null
            ? activeTimer.effectiveRemaining
            : task.durationSeconds;
    final progress = isTimedOut
        ? 1.0
        : activeTimer != null
            ? activeTimer.progress
            : 0.0;
    final isRunning = activeTimer?.isRunning ?? false;
    final ringColor = isTimedOut ? AppColors.danger : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 10,
                      backgroundColor: AppColors.ringTrack,
                      color: ringColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatTaskDuration(remaining),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: isTimedOut
                              ? AppColors.danger
                              : AppColors.textPrimary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isTimedOut
                            ? Translations.t(lang, 'tasks_times_up')
                            : Translations.t(lang, 'tasks_remaining'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isTimedOut ? FontWeight.w700 : FontWeight.w400,
                          color: isTimedOut
                              ? AppColors.danger
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (isTimedOut) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(taskTimerProvider.notifier).restart(task);
                  },
                  icon: const Icon(LucideIcons.rotateCcw),
                  label: Text(Translations.t(lang, 'tasks_restart')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await ref.read(tasksProvider.notifier).completeTask(task.id);
                    if (context.mounted) context.pop();
                  },
                  icon: const Icon(LucideIcons.circleCheck),
                  label: Text(Translations.t(lang, 'tasks_mark_done')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: activeTimer != null
                          ? () => ref
                              .read(taskTimerProvider.notifier)
                              .togglePause(task.id)
                          : null,
                      icon: Icon(isRunning ? LucideIcons.pause : LucideIcons.play),
                      label: Text(
                        isRunning
                            ? Translations.t(lang, 'tasks_pause')
                            : Translations.t(lang, 'tasks_resume'),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await ref.read(tasksProvider.notifier).completeTask(task.id);
                    if (context.mounted) context.pop();
                  },
                  icon: const Icon(LucideIcons.check),
                  label: Text(Translations.t(lang, 'tasks_complete_early')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
