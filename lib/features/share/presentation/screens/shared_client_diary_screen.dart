import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'share_access_screen.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error_handler.dart';

class SharedClientDiaryScreen extends ConsumerStatefulWidget {
  final String ownerId;
  final String displayName;

  const SharedClientDiaryScreen({
    super.key,
    required this.ownerId,
    required this.displayName,
  });

  @override
  ConsumerState<SharedClientDiaryScreen> createState() =>
      _SharedClientDiaryScreenState();
}

class _SharedClientDiaryScreenState
    extends ConsumerState<SharedClientDiaryScreen> {
  DateTime _date = DateTime.now();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _meals = [];
  List<Map<String, dynamic>> _exercises = [];

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);
  int get _tzOffset => -DateTime.now().timeZoneOffset.inMinutes;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _minDate => _today.subtract(const Duration(days: 365));

  bool get _canGoPrev => !_date.isBefore(_minDate.add(const Duration(days: 1)));
  bool get _canGoNext => _date.isBefore(_today);

  @override
  void initState() {
    super.initState();
    _date = _today;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(shareRepositoryProvider);
      final stats = await repo.getClientStats(
        widget.ownerId,
        date: _dateStr,
        tzOffset: _tzOffset,
      );
      final meals = await repo.getClientHistory(
        widget.ownerId,
        date: _dateStr,
        tzOffset: _tzOffset,
      );
      final exercises = await repo.getClientExercises(
        widget.ownerId,
        date: _dateStr,
        tzOffset: _tzOffset,
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _meals = meals;
        _exercises = exercises;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppErrorHandler.message(e);
        _loading = false;
      });
    }
  }

  Future<void> _shiftDay(int delta) async {
    final next = DateTime(_date.year, _date.month, _date.day + delta);
    if (next.isBefore(_minDate) || next.isAfter(_today)) return;
    HapticFeedback.selectionClick();
    setState(() => _date = next);
    await _load();
  }

  Future<void> _pickDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ShareDateSheet(
        selected: _date,
        minDate: _minDate,
        maxDate: _today,
      ),
    );
    if (picked == null) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);

    final calBudget = (_stats?['calorie_budget'] as num?)?.toInt() ?? 0;
    final cal = (_stats?['calories_consumed'] as num?)?.toInt() ?? 0;
    final protein = (_stats?['protein_consumed'] as num?)?.toInt() ?? 0;
    final carbs = (_stats?['carbs_consumed'] as num?)?.toInt() ?? 0;
    final fat = (_stats?['fat_consumed'] as num?)?.toInt() ?? 0;
    final proteinTarget = (_stats?['protein_target'] as num?)?.toInt() ?? 0;
    final carbsTarget = (_stats?['carbs_target'] as num?)?.toInt() ?? 0;
    final fatTarget = (_stats?['fat_target'] as num?)?.toInt() ?? 0;

    final isToday = _date.year == _today.year &&
        _date.month == _today.month &&
        _date.day == _today.day;
    final dateLabel = isToday
        ? t('today')
        : DateFormat.MMMEd(toIntlLocale(lang)).format(_date);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.displayName,
          style: AppTextStyles.bodyBold.copyWith(fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(LucideIcons.calendarDays, size: 20),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyRegular,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                          ),
                          child: Text(t('retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    children: [
                      _DateRail(
                        label: dateLabel,
                        canPrev: _canGoPrev,
                        canNext: _canGoNext,
                        onPrev: () => _shiftDay(-1),
                        onNext: () => _shiftDay(1),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),
                      _CaloriesCard(
                        consumed: cal,
                        budget: calBudget,
                        label: t('calories_label'),
                        leftLabel: t('left'),
                        overLabel: t('over_goal'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _MacroMini(
                              name: t('macro_protein'),
                              consumed: protein,
                              target: proteinTarget,
                              color: AppColors.protein,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MacroMini(
                              name: t('macro_carbs'),
                              consumed: carbs,
                              target: carbsTarget,
                              color: AppColors.carbs,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MacroMini(
                              name: t('macro_fats'),
                              consumed: fat,
                              target: fatTarget,
                              color: AppColors.fats,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _SectionLabel(t('share_meals')),
                      const SizedBox(height: 10),
                      if (_meals.isEmpty)
                        _EmptyState(
                          icon: LucideIcons.utensils,
                          text: t('share_no_meals'),
                        )
                      else
                        ..._meals.map((m) => _MealCard(meal: m)),
                      const SizedBox(height: 24),
                      _SectionLabel(t('share_workouts')),
                      const SizedBox(height: 10),
                      if (_exercises.isEmpty)
                        _EmptyState(
                          icon: LucideIcons.dumbbell,
                          text: t('share_no_workouts'),
                        )
                      else
                        ..._exercises.map((e) => _WorkoutCard(exercise: e)),
                    ],
                  ),
                ),
    );
  }
}

class _DateRail extends StatelessWidget {
  final String label;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTap;

  const _DateRail({
    required this.label,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: canPrev ? onPrev : null,
            icon: Icon(
              LucideIcons.chevronLeft,
              size: 20,
              color: canPrev ? AppColors.textPrimary : AppColors.inactive,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.calendarDays,
                      size: 16,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: canNext ? onNext : null,
            icon: Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: canNext ? AppColors.textPrimary : AppColors.inactive,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  final int consumed;
  final int budget;
  final String label;
  final String leftLabel;
  final String overLabel;

  const _CaloriesCard({
    required this.consumed,
    required this.budget,
    required this.label,
    required this.leftLabel,
    required this.overLabel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = budget > 0 ? (consumed / budget).clamp(0.0, 1.0) : 0.0;
    final left = budget - consumed;
    final over = left < 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$consumed',
            style: AppTextStyles.heroNumber.copyWith(fontSize: 40),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: AppTextStyles.bodyRegular.copyWith(fontSize: 14),
                ),
                TextSpan(
                  text: over ? '${-left} $overLabel' : '$left $leftLabel',
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 14,
                    color: over
                        ? const Color(0xFFE65100)
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.ringTrack,
              color: over ? const Color(0xFFE65100) : AppColors.primaryMid,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Goal $budget kcal',
            style: AppTextStyles.bodyRegular.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MacroMini extends StatelessWidget {
  final String name;
  final int consumed;
  final int target;
  final Color color;

  const _MacroMini({
    required this.name,
    required this.consumed,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${consumed}g', style: AppTextStyles.macroValue),
          const SizedBox(height: 2),
          Text(
            name,
            style: AppTextStyles.macroLabel.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.ringTrack,
              color: color,
            ),
          ),
          if (target > 0) ...[
            const SizedBox(height: 6),
            Text(
              '/ ${target}g',
              style: AppTextStyles.bodyRegular.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.sectionHeader.copyWith(fontSize: 18),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.inactive),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyRegular,
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    final name = meal['meal_name']?.toString() ??
        meal['name_en']?.toString() ??
        'Meal';
    final cal = meal['calories'] ?? 0;
    final p = meal['protein'] ?? 0;
    final c = meal['carbs'] ?? 0;
    final f = meal['fat'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.utensils,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyBold),
                const SizedBox(height: 4),
                Text(
                  'P $p · C $c · F $f',
                  style: AppTextStyles.bodyRegular.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '$cal kcal',
            style: AppTextStyles.bodyBold.copyWith(
              color: AppColors.primaryDark,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  const _WorkoutCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final name = exercise['name']?.toString() ?? 'Workout';
    final mins = exercise['duration_minutes'] ?? 0;
    final cal = exercise['calories_burned'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.dumbbell,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: AppTextStyles.bodyBold),
          ),
          Text(
            '$mins min · $cal kcal',
            style: AppTextStyles.bodyRegular.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Compact bottom-sheet calendar matching the home calendar aesthetic.
class _ShareDateSheet extends StatefulWidget {
  final DateTime selected;
  final DateTime minDate;
  final DateTime maxDate;

  const _ShareDateSheet({
    required this.selected,
    required this.minDate,
    required this.maxDate,
  });

  @override
  State<_ShareDateSheet> createState() => _ShareDateSheetState();
}

class _ShareDateSheetState extends State<_ShareDateSheet> {
  late DateTime _visibleMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateTime(
      widget.selected.year,
      widget.selected.month,
      widget.selected.day,
    );
    _visibleMonth = DateTime(_selected.year, _selected.month, 1);
  }

  DateTime get _minMonth =>
      DateTime(widget.minDate.year, widget.minDate.month, 1);
  DateTime get _maxMonth =>
      DateTime(widget.maxDate.year, widget.maxDate.month, 1);

  bool get _canBack => _visibleMonth.isAfter(_minMonth);
  bool get _canForward => _visibleMonth.isBefore(_maxMonth);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _enabled(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(widget.minDate) && !day.isAfter(widget.maxDate);
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_visibleMonth);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingEmpty = _visibleMonth.weekday - DateTime.monday;
    final weekdayLabels = List.generate(7, (i) {
      final date = DateTime(2024, 1, 1 + i);
      return DateFormat('EEEEE').format(date);
    });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: _canBack
                    ? () => setState(() {
                          _visibleMonth = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month - 1,
                            1,
                          );
                        })
                    : null,
                icon: Icon(
                  LucideIcons.chevronLeft,
                  color: _canBack ? AppColors.textPrimary : AppColors.inactive,
                ),
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 17),
                ),
              ),
              IconButton(
                onPressed: _canForward
                    ? () => setState(() {
                          _visibleMonth = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month + 1,
                            1,
                          );
                        })
                    : null,
                icon: Icon(
                  LucideIcons.chevronRight,
                  color:
                      _canForward ? AppColors.textPrimary : AppColors.inactive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: weekdayLabels
                .map(
                  (d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyRegular.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
            itemCount: leadingEmpty + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmpty) return const SizedBox.shrink();
              final day = index - leadingEmpty + 1;
              final date =
                  DateTime(_visibleMonth.year, _visibleMonth.month, day);
              final selected = _sameDay(date, _selected);
              final enabled = _enabled(date);
              final isToday = _sameDay(date, DateTime.now());

              return GestureDetector(
                onTap: !enabled
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _selected = date);
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryDark
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: !selected && isToday
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: !enabled
                          ? AppColors.inactive
                          : selected
                              ? Colors.white
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _selected),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Done', style: AppTextStyles.buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
