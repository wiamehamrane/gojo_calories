import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../domain/models/task_item.dart';
import '../../domain/duration_parser.dart';

class TaskGridCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final bool isTimerActive;
  final int? liveRemainingSeconds;
  final bool isTimerRunning;
  final bool isTimedOut;
  final String timedOutLabel;

  const TaskGridCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
    this.isTimerActive = false,
    this.liveRemainingSeconds,
    this.isTimerRunning = false,
    this.isTimedOut = false,
    this.timedOutLabel = 'TIME OUT',
  });

  @override
  Widget build(BuildContext context) {
    final durationLabel = isTimedOut
        ? '0m'
        : isTimerActive && liveRemainingSeconds != null
            ? formatTaskDuration(liveRemainingSeconds!)
            : task.durationLabel;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardElevated,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: task.completed ? onToggleComplete : onTap,
          onLongPress: onToggleComplete,
          child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 30, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: task.completed
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isTimedOut
                              ? LucideIcons.clockAlert
                              : isTimerActive
                                  ? LucideIcons.play
                                  : LucideIcons.timer,
                          size: 12,
                          color: isTimedOut
                              ? AppColors.danger
                              : isTimerActive
                                  ? AppColors.primaryDark
                                  : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          durationLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isTimedOut
                                ? AppColors.danger
                                : isTimerActive
                                    ? AppColors.primaryDark
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Icon(
                task.completed ? LucideIcons.circleCheck : LucideIcons.square,
                size: 16,
                color: task.completed
                    ? AppColors.primaryDark
                    : AppColors.inactive,
              ),
            ),
            if (isTimedOut)
              Positioned(
                top: 8,
                right: 28,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    timedOutLabel,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              )
            else if (isTimerActive)
              Positioned(
                top: 8,
                right: 28,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isTimerRunning ? 'LIVE' : 'PAUSED',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 2,
              right: 2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onDelete,
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      LucideIcons.x,
                      size: 14,
                      color: AppColors.inactive,
                    ),
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
