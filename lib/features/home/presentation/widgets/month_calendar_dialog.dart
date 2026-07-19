import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../stats/presentation/providers/calendar_progress_provider.dart';
import '../../../stats/presentation/providers/selected_date_provider.dart';
import 'calendar_day_colors.dart';

/// Full-month history calendar shown in a box. Users can page back through
/// months as far as the day they joined the app, and pick any day to view
/// that day's full history on the home screen.
Future<void> showMonthCalendarDialog(
  BuildContext context, {
  required DateTime joinDate,
  required DateTime today,
}) {
  return showDialog(
    context: context,
    barrierColor: const Color(0x66000000),
    builder: (_) => _MonthCalendarDialog(joinDate: joinDate, today: today),
  );
}

class _MonthCalendarDialog extends ConsumerStatefulWidget {
  final DateTime joinDate;
  final DateTime today;

  const _MonthCalendarDialog({required this.joinDate, required this.today});

  @override
  ConsumerState<_MonthCalendarDialog> createState() =>
      _MonthCalendarDialogState();
}

class _MonthCalendarDialogState extends ConsumerState<_MonthCalendarDialog> {
  late DateTime _visibleMonth; // first day of the shown month

  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedDateProvider);
    _visibleMonth = DateTime(selected.year, selected.month, 1);
  }

  DateTime get _minMonth =>
      DateTime(widget.joinDate.year, widget.joinDate.month, 1);

  DateTime get _maxMonth => DateTime(widget.today.year, widget.today.month, 1);

  bool get _canGoBack => _visibleMonth.isAfter(_minMonth);

  bool get _canGoForward => _visibleMonth.isBefore(_maxMonth);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final locale = toIntlLocale(lang);
    final selectedDate = ref.watch(selectedDateProvider);
    final progressAsync = ref.watch(calendarProgressProvider);
    final progressMap = progressAsync.hasValue ? progressAsync.value : null;

    final monthLabel = DateFormat('MMMM yyyy', locale).format(_visibleMonth);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // Weekday of the 1st, as offset from Monday (0 = Monday).
    final leadingEmpty = _visibleMonth.weekday - DateTime.monday;

    final weekdayLabels = List.generate(7, (i) {
      final date = DateTime(2024, 1, 1 + i); // 2024-01-01 is a Monday
      return DateFormat('EEEEE', locale).format(date);
    });

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavChevron(
                  icon: LucideIcons.chevronLeft,
                  enabled: _canGoBack,
                  onTap: () => _changeMonth(-1),
                ),
                Text(
                  monthLabel,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                _NavChevron(
                  icon: LucideIcons.chevronRight,
                  enabled: _canGoForward,
                  onTap: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: weekdayLabels
                  .map(
                    (label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: leadingEmpty + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingEmpty) return const SizedBox.shrink();
                final day = index - leadingEmpty + 1;
                final date =
                    DateTime(_visibleMonth.year, _visibleMonth.month, day);
                final isSelected = _sameDay(date, selectedDate);
                final isToday = _sameDay(date, widget.today);
                final isDisabled = date.isAfter(widget.today) ||
                    date.isBefore(widget.joinDate);
                final dayColor = CalendarDayColors.forDate(date);
                final dayProgress = lookupCalendarProgress(progressMap, date);
                final hasData = (dayProgress?.caloriesConsumed ?? 0) > 0;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isDisabled
                      ? null
                      : () {
                          ref
                              .read(selectedDateProvider.notifier)
                              .setDate(date);
                          Navigator.of(context).pop();
                        },
                  child: Opacity(
                    opacity: isDisabled ? 0.3 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primaryDark
                            : Colors.transparent,
                        border: isToday && !isSelected
                            ? Border.all(color: dayColor, width: 1.5)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (hasData && !isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
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
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavChevron extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavChevron({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryLight : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.primary : AppColors.inactive,
        ),
      ),
    );
  }
}
