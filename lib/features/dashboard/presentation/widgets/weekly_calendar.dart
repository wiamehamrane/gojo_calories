import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/selected_date_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'dotted_circle_painter.dart';

class WeeklyCalendar extends ConsumerWidget {
  const WeeklyCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final selectedDate = ref.watch(selectedDateProvider);
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    // Start of current week (Sunday)
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    return SizedBox(
      height: 72,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final dayDate = startOfWeek.add(Duration(days: i));
          final isSelected = dayDate.year == selectedDate.year &&
              dayDate.month == selectedDate.month &&
              dayDate.day == selectedDate.day;
          final isFuture = dayDate.isAfter(now);
          final dayOfMonth = dayDate.day;

          Widget decorationWidget;
          if (isSelected) {
            decorationWidget = Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark,
              ),
              child: Center(
                child: Text(
                  "$dayOfMonth",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          } else {
            decorationWidget = SizedBox(
              width: 36,
              height: 36,
              child: CustomPaint(
                painter: DottedCirclePainter(
                  color: isFuture ? const Color(0xFFDDDDDD) : AppColors.inactive.withValues(alpha: 0.6),
                  strokeWidth: 2.0,
                  dashWidth: 4.0,
                  dashSpace: 3.0,
                ),
                child: Center(
                  child: Text(
                    "$dayOfMonth",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isFuture ? AppColors.inactive : Colors.black, // pure black based on spec
                    ),
                  ),
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: isFuture
                ? null
                : () => ref.read(selectedDateProvider.notifier).setDate(dayDate),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  days[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.textPrimary : (isFuture ? AppColors.inactive : const Color(0xFF6B6B6B)), // pure grey
                  ),
                ),
                const SizedBox(height: 6),
                decorationWidget,
              ],
            ),
          );
        }),
      ),
    );
  }
}
