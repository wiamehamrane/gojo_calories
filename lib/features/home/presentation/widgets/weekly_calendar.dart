import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../features/stats/presentation/providers/selected_date_provider.dart';
import '../../../stats/presentation/providers/calendar_progress_provider.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'calendar_day_colors.dart';
import 'day_progress_ring.dart';

class WeeklyCalendar extends ConsumerStatefulWidget {
  const WeeklyCalendar({super.key});

  @override
  ConsumerState<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends ConsumerState<WeeklyCalendar> {
  static const _pastDays = 365;
  static const _itemWidth = 52.0;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToDate(ref.read(selectedDateProvider), animate: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _startDate() => _today.subtract(const Duration(days: _pastDays));

  DateTime _dateAtIndex(int index) => _startDate().add(Duration(days: index));

  int _indexForDate(DateTime date) {
    final diff = _normalize(date).difference(_startDate()).inDays;
    return diff.clamp(0, _pastDays);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _scrollToDate(DateTime date, {bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final index = _indexForDate(date);
    final viewport = MediaQuery.of(context).size.width;
    final offset =
        (index * _itemWidth) - (viewport / 2) + (_itemWidth / 2);
    final max = _scrollController.position.maxScrollExtent;
    final target = offset.clamp(0.0, max);

    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final progressAsync = ref.watch(calendarProgressProvider);
    final progressMap =
        progressAsync.hasValue ? progressAsync.value : null;
    final today = _today;
    final lang = ref.watch(localeProvider);
    final locale = toIntlLocale(lang);

    ref.listen<DateTime>(selectedDateProvider, (previous, next) {
      if (previous != null && !_sameDay(previous, next)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToDate(next);
        });
      }
    });

    return SizedBox(
      height: 72,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _pastDays + 1,
        itemBuilder: (context, index) {
          final dayDate = _dateAtIndex(index);
          final isSelected = _sameDay(dayDate, selectedDate);
          final isToday = _sameDay(dayDate, today);
          final dayLabel = DateFormat('EEE', locale).format(dayDate);
          final dayOfMonth = dayDate.day;
          final dayColor = CalendarDayColors.forDate(dayDate);
          final dayProgress = lookupCalendarProgress(progressMap, dayDate);
          final progress = dayProgress?.progress ?? 0.0;
          final isOverGoal = dayProgress?.isOverGoal ?? false;
          final hasData = (dayProgress?.caloriesConsumed ?? 0) > 0;

          return SizedBox(
            width: _itemWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                ref.read(selectedDateProvider.notifier).setDate(dayDate);
              },
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
                    dayOfMonth: dayOfMonth,
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
        },
      ),
    );
  }
}
