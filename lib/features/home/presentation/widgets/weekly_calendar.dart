import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../features/stats/presentation/providers/selected_date_provider.dart';
import '../../../stats/presentation/providers/calendar_progress_provider.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'calendar_day_colors.dart';
import 'day_progress_ring.dart';

/// Fixed Monday–Sunday week strip (no infinite scrolling). Future days are
/// disabled.
class WeeklyCalendar extends ConsumerWidget {
  const WeeklyCalendar({super.key});

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Monday of the week containing [date].
  DateTime _mondayOf(DateTime date) {
    final d = _normalize(date);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final progressAsync = ref.watch(calendarProgressProvider);
    final progressMap = progressAsync.hasValue ? progressAsync.value : null;
    final now = DateTime.now();
    final today = _normalize(now);
    final lang = ref.watch(localeProvider);
    final locale = toIntlLocale(lang);

    // Show the Mon–Sun week that contains the selected date.
    final monday = _mondayOf(selectedDate);

    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (int i = 0; i < 7; i++)
              Expanded(
                child: _buildDayCell(
                  ref,
                  date: monday.add(Duration(days: i)),
                  selectedDate: selectedDate,
                  today: today,
                  progressMap: progressMap,
                  locale: locale,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(
    WidgetRef ref, {
    required DateTime date,
    required DateTime selectedDate,
    required DateTime today,
    required Map<String, DayCalorieProgress>? progressMap,
    required String locale,
  }) {
    final isSelected = _sameDay(date, selectedDate);
    final isToday = _sameDay(date, today);
    final isDisabled = date.isAfter(today);
    final dayLabel = DateFormat('EEE', locale).format(date);
    final dayColor = CalendarDayColors.forDate(date);
    final dayProgress = lookupCalendarProgress(progressMap, date);
    final progress = dayProgress?.progress ?? 0.0;
    final isOverGoal = dayProgress?.isOverGoal ?? false;
    final hasData = (dayProgress?.caloriesConsumed ?? 0) > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isDisabled
          ? null
          : () => ref.read(selectedDateProvider.notifier).setDate(date),
      child: Opacity(
        opacity: isDisabled ? 0.35 : 1.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.textPrimary
                    : const Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(height: 6),
            DayProgressRing(
              dayOfMonth: date.day,
              progress: progress,
              isOverGoal: isOverGoal,
              isSelected: isSelected,
              dayColor: dayColor,
              hasData: hasData,
            ),
            if (isToday && !isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: dayColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
