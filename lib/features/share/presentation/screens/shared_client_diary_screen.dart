import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'share_access_screen.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _date = picked);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.displayName),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(LucideIcons.calendar),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.calendarDays, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat.yMMMEd().format(_date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _macroCard(
                        title: t('share_calories'),
                        value: '$cal / $calBudget',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _macroCard(
                              title: t('macro_protein'),
                              value: '${protein}g',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _macroCard(
                              title: t('macro_carbs'),
                              value: '${carbs}g',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _macroCard(
                              title: t('macro_fats'),
                              value: '${fat}g',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('share_meals'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_meals.isEmpty)
                        _empty(t('share_no_meals'))
                      else
                        ..._meals.map(_mealTile),
                      const SizedBox(height: 20),
                      Text(
                        t('share_workouts'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_exercises.isEmpty)
                        _empty(t('share_no_workouts'))
                      else
                        ..._exercises.map(_exerciseTile),
                    ],
                  ),
                ),
    );
  }

  Widget _macroCard({required String title, required String value}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _mealTile(Map<String, dynamic> meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['meal_name']?.toString() ?? 'Meal',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'P ${meal['protein'] ?? 0} · C ${meal['carbs'] ?? 0} · F ${meal['fat'] ?? 0}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${meal['calories'] ?? 0} kcal',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _exerciseTile(Map<String, dynamic> ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.footprints, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ex['name']?.toString() ?? 'Workout',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${ex['duration_minutes'] ?? 0} min · ${ex['calories_burned'] ?? 0} kcal',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
